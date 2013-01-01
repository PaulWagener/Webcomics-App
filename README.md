# Webcomics

Browse all your favorite webcomics with this handy app.

#Explanation of the strings

To make a custom site you have to make a string that looks like this:

`▄█name:XKCD█credits:Randall Munroe█base:http://xkcd.com█comic:<img src="([^>]*?)" title=█alt:<img.*?alt=.*?title="([^"]*?)"█archive:http://xkcd.com/archive/█archivepart:<h1>Drawings:</h1>(.*?)</div>█archivelink:href="([^"]*?)"█archivetitle:<a.*?>([^<]*?)<█archiveorder:recenttop█▄`

The string must start and end with a ▄ and has █key:value█'s between them that are in no particular order. No enters are allowed in the string, read up on how to use whitespace in regex if you must use them.

There are two types of webcomic navigation: Next-previous navigation and archivenavigation. 

* Next previous navigation is applicable for webcomics that offer on every comicpage a link to the next and the previous comic. This is true for most comics. 
* Archive navigation is applicable for webcomics that offer a dedicated page where all comics are linked to.
If both types are applicable the archive navigation type is preferred as it enables a list for quick access to each comic.

## Key values

Values for all types of comics:

* **name**: The name of the webcomic as it will appear in the menus. **(required)**
* **credits**: The name of the person(s) who created the comic. (optional)
* **base**: Part of a URL that will be prefixed to all other captured URL where applicable. (optional)
* *comic*: A regex that captures the URL of the image from the source of the comicpage. **(required)**
* **title**: A regex that captures the title of the comic. (optional)
* **alt**: A regex that captures an additional text punchline from the source of the comicpage. Usually in the alt/title text of the image.  (optional)
* **news**: A regex capturing a string of HTML from the source of the comicpage containing a news item that accompanies the comic on the comicpage. (optional)
* **hiddencomic**: A regex capturing capturing a URL from the source of the comicpage (or the source of the hiddencomic page if hiddencomiclink is defined) to an image file usually containing an additional punchline. (optional) 
* **hiddencomiclink**: A regex capturing capturing a URL from the source of the comicpage that points to a page that has the hidden comic. Defining this means hiddencomic becomes required. (optional)

If comic uses the next-previous navigation type all following fields are required. Do not set values for archivetype fields.  

* **first**: The URL of the comicpage containing the first comic. 
* **last**: The URL of the comicpage containing the last comic.
* **previous**: A regex that captures a URL from the source of the comicpage that points to the previous comicpage.
* **next**: A regex that captures a URL from the source of the comicpage that points to the next comicpage.
   
If comic uses archive type all following fields are required. Do not set values for previous-next navigation type.
  
* **archive**: A full URL to the page where the archive of the comic is.
* **archivepart**: A regex that captures a substring of the source of the archivepage on which the below regexes are applied. You can use `(.*)` if you want to use the whole archivepage.
* **archivelink**: A regex that captures the links to all the comicpages from the string captured with archivepart.
* **archivetitle**: A regex that captures the titles of all comics from the string captured with archivepart, must be exactly equal to the amount of links captured.
* **archiveorder**: 'recenttop' if the most recent comic is first on the page. 'recentbottom' if the most recent comic is last on the page. 

## Tips and tricks

Capturing stuff with regexes is done with parentheses. There are three regex templates you will most likely use. 

* `<uniquestringinsource>(.?)<endstring>` Used for when the link you want to capture is after a unique string in the source. 

* `<startstring>([^"].*?)<uniquestringinsource>` Used for when the link you want is followed by a unique string. The " should be replaced by a character that is not in the string you want to capture but is in every larger string that also matches the pattern. Usually you only use one of these three: `"<>`.

* `(<uniquestringpartoflink>.*?)<endstring>` Used for when a URL itself is partly unique.
 
The unique string doesn't have to be unique perse. It is enough if the first thing you capture is always the thing you want. 

If the above doesn't make sense to you please read up on **regular expressions** and how they work.

I've made a tool so you can [test and build](http://webcomicsapp.appspot.com/) a string. Try filling in the above XKCD string and see how it works. The checkmark next to go enables seperate editing fields instead of the big input thing.

You can also view the [examples](https://raw.github.com/PaulWagener/Webcomics-App/master/webcomiclist.txt) for all comics included in the app and is a good starting point for learning how the system works. If you are seeing â–„â–ˆ instead of the blocks in firefox select View>Character Set>Unicode(UTF-8)

This list needs to be maintained regularly as sites redesign their layouts all the time. To get an overview which sites need fixing simply run the webcomicsite.py script on the command line.

**Did you succesfully make a string** for a comic not yet in the repository? If you are logged to GitHub you can edit the database [here](https://github.com/PaulWagener/Webcomics-App/edit/master/webcomiclist.txt). The goal is to have every webcomic in there.
