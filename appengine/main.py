#!/usr/bin/env python
#
# Copyright 2007 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
from google.appengine.ext import webapp
from google.appengine.ext.webapp import util
from google.appengine.ext.webapp import template

from webcomicsite import WebcomicSite

class MainHandler(webapp.RequestHandler):
    def get(self):

        template_values = {
            'keys': ['name', 'credits', 'base', 'first', 'previous', 'next', 'last', 'comic',
                'hiddencomic', 'hiddencomiclink', 'title', 'alt', 'news',
                'archive', 'archivepart', 'archivelink', 'archivetitle', 'archiveorder']
        }

        self.response.out.write(template.render('index.html', template_values))

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

            if 'archive' in webcomicsite.keys:

                #Load the archive!
                archive = webcomicsite.get_archive()
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

            def search_key(key):
                if not key in webcomicsite.keys:
                    return '<i>Not defined</i>'
                else:
                    return webcomicsite.search(webcomicsite.keys[key], source)

            template_values['webcomicsite'] = webcomicsite
            template_values['comic'] = search_key('comic')
            template_values['comic_url'] = webcomicsite.url(template_values['comic'])
            template_values['alt'] = search_key('alt')
            template_values['hiddencomic'] = search_key('hiddencomic')
            template_values['hiddencomiclink'] = search_key('hiddencomiclink')
            if not template_values['hiddencomic'].startswith('<i>'):
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
