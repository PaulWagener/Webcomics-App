#!/usr/bin/env python
# Encoding: utf-8

# This thing runs at http://webcomicsapp.appspot.com/ and allows you to create and/or debug
# webcomic strings (the ones that look like "▄█name:ComicZ█credit:Author█▄")
# A list of 'official' strings can be found at http://code.google.com/p/webcomicsapp/source/browse/trunk/webcomiclist.txt

from google.appengine.ext import webapp
from google.appengine.ext.webapp import util
from google.appengine.ext.webapp import template

from webcomicsite import WebcomicSite

class MainHandler(webapp.RequestHandler):
    """
        The get prints out the main page with the <iframe>
    """
    def get(self):

        template_values = {
            'keys': ['name', 'credits', 'base', 'first', 'previous', 'next', 'last', 'comic',
                'hiddencomic', 'hiddencomiclink', 'title', 'alt', 'news',
                'archive', 'archivepart', 'archivelink', 'archivetitle', 'archiveorder']
        }

        template_values['definition'] = self.request.get('definition')
        template_values['url'] = self.request.get('url')

        self.response.out.write(template.render('index.html', template_values))

    """
        The post gets a definition (and perhaps a url) to test out.
        This will always be loaded inside the green <iframe>
    """
    def post(self):
        

        definition = self.request.get('definition')
        url = self.request.get('url')
        template_values = {'definition': definition, 'exception': ''}
        try:
            webcomicsite = WebcomicSite(definition)
            title = ''
            first = ''
            last = ''
            previous = ''
            next = ''

            if webcomicsite.hasArchive():

                #Load the archive!
                archive = webcomicsite.get_archive()

                if len(archive) == 0:
                    raise Exception('No archive entries matched')

                template_values['archive'] = archive

                if not url:
                    url = webcomicsite.url(archive[-1][0])

                #Find where in the archive we are
                links,titles = zip(*archive)

                try:
                    index = links.index(url)
                except:
                    raise Exception('URL "%s" not found in archive' % url)

                #Load title, next, previous, last & first relative to this comic
                title = archive[index][1]

                if index > 0:
                    previous = archive[index - 1][0]
                    
                if index < len(archive) - 1:
                    next = archive[index + 1][0]
                    
                first = archive[0][0]
                last = archive[-1][0]
                
                

            else:
                if not url:
                    url = webcomicsite.url(webcomicsite.keys['last'])

                first = webcomicsite.keys['first']
                last = webcomicsite.keys['last']

            template_values['url'] = url




            # Get the comic
            source = webcomicsite.source(url)

            # Try to find previous and next comic in source (they may not exist for the first and last comic)
            if not webcomicsite.hasArchive():
                try:
                    previous = webcomicsite.search(webcomicsite.keys['previous'], source)
                except:
                    pass

                try:
                    next = webcomicsite.search(webcomicsite.keys['next'], source)
                except:
                    pass

            notdefined = '<i>Not defined</i>'
            def search_key(key):
                if not key in webcomicsite.keys:
                    return notdefined
                else:
                    return webcomicsite.search(webcomicsite.keys[key], source)

            template_values['webcomicsite'] = webcomicsite
            template_values['comic'] = search_key('comic')
            template_values['comic_url'] = webcomicsite.url(template_values['comic'])
            template_values['alt'] = search_key('alt')
            
            template_values['hiddencomiclink'] = search_key('hiddencomiclink')

            if template_values['hiddencomiclink'] != notdefined:
                hiddencomicSource = webcomicsite.source(template_values['hiddencomiclink'])
                template_values['hiddencomic'] = webcomicsite.search(webcomicsite.keys['hiddencomic'], hiddencomicSource)
            else:
                template_values['hiddencomic'] = search_key('hiddencomic')


            if template_values['hiddencomic'] != notdefined:
                template_values['hiddencomic_url'] = webcomicsite.url(template_values['hiddencomic'])
            template_values['news'] = search_key('news')

            template_values['first'] = first
            template_values['previous'] = previous
            template_values['next'] = next
            template_values['last'] = last

            template_values['first_url'] = webcomicsite.url(first)
            template_values['previous_url'] = webcomicsite.url(previous)
            template_values['next_url'] = webcomicsite.url(next)
            template_values['last_url'] = webcomicsite.url(last)

            if 'archive' in webcomicsite.keys:
                template_values['title'] = title
            else:
                template_values['title'] = search_key('title')


        except Exception as e:
            template_values['exception'] = str(e)
        

        

        self.response.out.write(template.render('comic.html', template_values))


def main():
    application = webapp.WSGIApplication([('/', MainHandler)],
                                         debug=True)
    util.run_wsgi_app(application)


if __name__ == '__main__':
    main()
