# Encoding: utf-8

class bcolors:
    """

    """
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'

    def disable(self):
        self.HEADER = ''
        self.OKBLUE = ''
        self.OKGREEN = ''
        self.WARNING = ''
        self.FAIL = ''
        self.ENDC = ''
        
import re, urllib2

class WebcomicSite:
    """"""

    keys = {}

    # Parse the comic definition
    def __init__(self, definition):
            if not definition.startswith(u'▄'):
                    raise Exception(u'Webcomic definition didn\'t start with ▄')

            if not definition.endswith(u'▄'):
                    raise Exception(u'Webcomic definition didn\'t start with ▄')

            #Extract fields from definition
            keyvalues = definition.strip(u'▄').strip(u'█').split(u'█')
            
            for keyvalue in keyvalues:
                match = re.match('([a-z]+):(.*)', keyvalue)
                key = match.group(1)
                value = match.group(2)
                self.keys[key] = value

            #Check for required fields
            if not self.keys['name']:
                raise Exception('key "name" not defined')

            if not self.keys['comic']:
                raise Exception('key "comic" not defined')

            if 'archive' in self.keys:
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

            else:
                if not 'first' in self.keys:
                    raise Exception('key "first" not defined')

                if not 'last' in self.keys:
                    raise Exception('key "last" not defined')

                if not 'previous' in self.keys:
                    raise Exception('key "previous" not defined')

                if not 'next' in self.keys:
                    raise Exception('key "next" not defined')

    # Returns a url prepended with the base (if it exists)
    def url(self, url):
        if 'base' in self.keys and not url.startswith('http://'):
            return self.keys['base'] + url
        else:
            return url

    def source(self, url):
        try:
            return urllib2.urlopen(self.url(url)).read()
        except Exception as e:
            raise Exception(url + ': ' + str(e))

    def test(self):
        if 'archive' in self.keys:
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

                next = re.search('(?s)' + self.keys['next'], source)
                if next is None:
                    raise Exception('Next link not found on page ' + url)

                url = next.group(1)

            # Try the last three comics
            url = self.keys['last']
            for i in range(3):
                source = self.test_comic(url)

                previous = re.search('(?s)' + self.keys['previous'], source)
                if previous is None:
                    raise Exception('Previous link not found on page ' + url)

                url = previous.group(1)


    # Test a single comic to see if everything works
    def test_comic(self, comicUrl):
        source = self.source(comicUrl)

        comic = re.search('(?s)' + self.keys['comic'], source)
        if comic is None:
            raise Exception('Comic image not found in source')

        # Try to download comic (should raise 404 or somesuch exception if it fails)
        self.source(comic.group(1))

        if 'title' in self.keys:
            title = re.search('(?s)' + self.keys['title'], source)

            if title is None:
                raise Exception('Comic title not found in source')

        if 'alt' in self.keys:
            alt = re.search('(?s)' + self.keys['alt'], source)

            if alt is None:
                raise Exception('Alt text not found in source')

        if 'news' in self.keys:
            news = re.search('(?s)' + self.keys['news'], source)

            if news is None:
                raise Exception('News HTML not found in source')

        if 'hiddencomic' in self.keys:
            hiddencomicSource = source

            if 'hiddencomiclink' in self.keys:
                hiddencomicUrl = re.search('(?s)' + self.keys['hiddencomiclink'], source)

                if hiddencomicUrl is None:
                    raise Exception('Hidden comic link not found in source')

                hiddencomicSource = self.source(hiddencomicUrl)

            hiddencomic = re.search('(?s)' + self.keys['hiddencomic'], hiddencomicSource)

            #Try to download hidden comic
            self.source(hiddencomic.group(1))

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
        




def test_definition(definition):
    webcomicsite = WebcomicSite(definition)

    # Pretty printing!
    printstring = 'Testing ' + bcolors.OKBLUE + webcomicsite.keys['name'] + bcolors.ENDC
    print printstring,
    print " " * (50 - len(printstring)),

    # Do the test
    try:
        webcomicsite.test()
        print bcolors.OKGREEN + "[OK]" + bcolors.ENDC
    except Exception as e:
        print bcolors.FAIL + "[ERROR] " + bcolors.ENDC + str(e)

if __name__ == "__main__":
    main()

    comics = open('webcomiclist.txt').readlines()
    #test_definition(comics[2].strip().decode('utf-8'))
    for comic in comics[1:]:
        definition = comic.strip().decode('utf-8')
        test_definition(definition)


    