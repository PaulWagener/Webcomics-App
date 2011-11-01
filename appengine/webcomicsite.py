# Encoding: utf-8

import re, urllib2, sys

class bcolors:
    """
    A list of colors to spice up the console output
    """
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
        

class WebcomicSite:
    """
    Class that parses a webcomic string and checks it is valid
    Can also perform tests to see if the definition still works
    """

    keys = {}

    # Parse the comic definition
    def __init__(self, definition):
            if not definition.startswith(u'▄'):
                    raise Exception('Webcomic definition didn\'t start with ▄')

            if not definition.endswith(u'▄'):
                    raise Exception('Webcomic definition didn\'t end with ▄')

            #Extract fields from definition
            keyvalues = definition.strip(u'▄').strip(u'█').split(u'█')

            self.keys = {}
            
            for keyvalue in keyvalues:
                match = re.match('([a-z]+):(.*)', keyvalue)
                if match:
                    key = match.group(1)
                    value = match.group(2)
                    self.keys[key] = value

            #Check for required fields

            if not 'name' in self.keys:
                raise Exception('key "name" not defined')

            if not 'comic' in self.keys:
                raise Exception('key "comic" not defined')

            if 'hiddencomiclink' in self.keys and not 'hiddencomic' in self.keys:
                raise Exception('if key "hiddencomiclink" is defined key "hiddencomic" should also be defined')

            if self.hasArchive():
                if not 'archivepart' in self.keys:
                    raise Exception('key "archivepart" not defined')

                if not 'archivelink' in self.keys:
                    raise Exception('key "archivelink" not defined')

                if not 'archivetitle' in self.keys:
                    raise Exception('key "archivetitle" not defined')

                if not 'archiveorder' in self.keys:
                    raise Exception('key "archiveorder" not defined')

                if self.keys['archiveorder'] != 'recenttop' and self.keys['archiveorder'] != 'recentbottom':
                    raise Exception('key "archiveorder" must be "recenttop" or "recentbottom"')

                if 'first' in self.keys:
                    raise Exception('if key "archive" is defined key "first" should not be defined')

                if 'last' in self.keys:
                    raise Exception('if key "archive" is defined key "last" should not be defined')

                if 'previous' in self.keys:
                    raise Exception('if key "archive" is defined key "previous" should not be defined')

                if 'next' in self.keys:
                    raise Exception('if key "archive" is defined key "next" should not be defined')

                if 'title' in self.keys:
                    raise Exception('if key "archive" is defined key "title" should not be defined')

            else:
                if not 'first' in self.keys:
                    raise Exception('key "first" not defined')

                if not 'last' in self.keys:
                    raise Exception('key "last" not defined')

                if not 'previous' in self.keys:
                    raise Exception('key "previous" not defined')

                if not 'next' in self.keys:
                    raise Exception('key "next" not defined')

                if 'archivepart' in self.keys:
                    raise Exception('if key "archive" is undefined, key "archivepart" should not be defined')

                if 'archivelink' in self.keys:
                    raise Exception('if key "archive" is undefined, key "archivelink" should not be defined')

                if 'archivetitle' in self.keys:
                    raise Exception('if key "archive" is undefined, key "archivetitle" should not be defined')

                if 'archiveorder' in self.keys:
                    raise Exception('if key "archive" is undefined, key "archiveorder" should not be defined')



    # Returns a url prepended with the base (if it exists)
    def url(self, url):
        if 'base' in self.keys and not (url.startswith('http://') or url.startswith('https://')):
            return self.keys['base'] + url
        else:
            return url

    # Get the source of a url (which may be without a base)
    def source(self, url):
        try:
            # Spoof the user agent, some webcomics have a problem with scraping (So don't modify this script for scraping!)
            return urllib2.urlopen(urllib2.Request(self.url(url), None, {'User-Agent': 'illa/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.106 Safari/535.2'})).read()
        except Exception as e:
            raise Exception(url + ': ' + repr(e) + ' ' + str(e))

    # Try to find pattern in text, returns the first group in the pattern
    # Will raise an exception if pattern is not matched
    def search(self, pattern, text):
        match = re.search('(?s)' + pattern, text)

        if match is None:
            raise Exception('Pattern "%s" does not match anything in source' % pattern)

        if len(match.groups()) == 0:
            raise Exception('Pattern "%s" does not capture atleast one group' % pattern)

        return match.group(1)

    def hasArchive(self):
        return 'archive' in self.keys

    # Try to download the first three comics and last three comics.
    # Will throw an exception if anything at all is wrong
    # Otherwise it will return peacefully
    def test(self):
        if self.hasArchive():
            archive = self.get_archive()
            if len(archive) == 0:
                raise Exception('No comics found in archive')

            # Test first three comics
            self.test_comic(archive[0][0])
            self.test_comic(archive[1][0])
            self.test_comic(archive[2][0])

            # Test the last three comics
            self.test_comic(archive[-1][0])
            self.test_comic(archive[-2][0])
            self.test_comic(archive[-3][0])
        else:
            # Try the first three comics
            url = self.keys['first']
            for i in range(3):
                source = self.test_comic(url)
                next = self.search(self.keys['next'], source)
                url = next

            # Try the last three comics
            url = self.keys['last']
            for i in range(3):
                source = self.test_comic(url)
                previous = self.search(self.keys['previous'], source)
                url = previous


    # Test a single comic to see if everything works
    # Throws an exception if something is wrong, will return the source of the comic if everything checks out.
    def test_comic(self, comicUrl):
        source = self.source(comicUrl)

        comic = self.search(self.keys['comic'], source)

        # Try to download comic (should raise 404 or somesuch exception if it fails)
        self.source(comic)

        if 'title' in self.keys:
            title = self.search(self.keys['title'], source)

        if 'alt' in self.keys:
            alt = self.search(self.keys['alt'], source)

        if 'news' in self.keys:
            news = self.search(self.keys['news'], source)

        if 'hiddencomic' in self.keys:
            hiddencomicSource = source

            if 'hiddencomiclink' in self.keys:
                hiddencomicUrl = self.search(self.keys['hiddencomiclink'], source)

                hiddencomicSource = self.source(hiddencomicUrl)

            hiddencomic = self.search(self.keys['hiddencomic'], hiddencomicSource)

            #Try to download hidden comic
            self.source(hiddencomic)

        return source

    # Test various aspects of archive navigation
    def get_archive(self):
        archiveSource = self.source(self.keys['archive'])

        #Reduce source to just the relevant archive part
        archivePart = re.search('(?s)' + self.keys['archivepart'], archiveSource)

        if archivePart is None:
            raise Exception('archivepart pattern "%s" does not match on archive source' % self.keys['archivepart'])
        archivePart = archivePart.group(1)

        # find all links
        links = re.findall('(?s)' + self.keys['archivelink'], archivePart)

        links = map(self.url, links)

        # Find all titles
        titles = re.findall('(?s)' + self.keys['archivetitle'], archivePart)

        if self.keys['archiveorder'] == 'recenttop':
            links.reverse()
            titles.reverse()

        if len(links) != len(titles):
            raise Exception('Found a different number of links & titles (%s links versus %s titles)' %(len(links), len(titles)))

        return zip(links, titles)
        



# Test out if a definition still works
# Will pretty print out [ OK ] or [ ERROR ] followed by the error
def test_definition(i, definition):
    webcomicsite = WebcomicSite(definition)

    # Pretty printing!
    printstring = str(i) + '. Testing ' + bcolors.OKBLUE + webcomicsite.keys['name'] + bcolors.ENDC
    print printstring,
    print " " * (50 - len(printstring)),
    sys.stdout.flush()

    # Do the test
    try:
        webcomicsite.test()
        print bcolors.OKGREEN + "[OK]" + bcolors.ENDC
    except Exception as e:
        print bcolors.FAIL + "[ERROR] " + bcolors.ENDC + repr(e)

if __name__ == "__main__":
    comics = open('../webcomiclist.txt').readlines()
    comics = map(lambda x: x.strip().decode('utf-8'), comics)

    # Range of comics to test
    start = 1
    end = len(comics) - 1 #inclusive

    # User defined range
    if len(sys.argv) == 2:
        startend = sys.argv[1].split('-')

        if startend[0]:
            start = int(startend[0])

        if startend[-1]:
            end = int(startend[-1])

    # Test all comics in range (can take a long LONG time)
    for i, comic in enumerate(comics):
        
        if start <= i and i <= end:
            test_definition(i, comic)    