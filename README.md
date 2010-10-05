# Font Squirreler

## Description

This is a Thor script that install webfonts from
[http://fontsquirrel.com](http://fontsquirrel.com) locally
or to s3.

This script is opinionated in that it changes the downloaded
stylesheets by inlining the TTF font. This clears up cross domain
issues and really helps if you want to host the files on S3 or Cloud
Front.

This script also splits the given CSS file into separate files for
each font varient so that you can selectively use each varient at
will.

The script further changes the filenames and directory scheme to ease
programatic use of the fonts.

This script doesn't mess with WOFF files because they have to be
inlined for S3 as well which doubles the file size.  Just kinda
silly.

This is "beta but useful" or "betauseful" software.  

## Installation 

    thor install http://github.com/bhauman/font_squirreler/raw/master/font_squirreler.thor 

## Usage

    thor font_squirreler:search Sans

Which outputs:

    1:  http://www.fontsquirrel.com/fonts/Aurulent-Sans
    2:  http://www.fontsquirrel.com/fonts/Aurulent-Sans-Mono
    3:  http://www.fontsquirrel.com/fonts/aw-conqueror-sans
    4:  http://www.fontsquirrel.com/fonts/Bitstream-Vera-Sans
    5:  http://www.fontsquirrel.com/fonts/Bitstream-Vera-Sans-Mono
    6:  http://www.fontsquirrel.com/fonts/COM4t-Sans-Medium
    7:  http://www.fontsquirrel.com/fonts/DejaVu-Sans
    8:  http://www.fontsquirrel.com/fonts/DejaVu-Sans-Mono
    9:  http://www.fontsquirrel.com/fonts/Droid-Sans
    10:  http://www.fontsquirrel.com/fonts/Droid-Sans-Mono
    11:  http://www.fontsquirrel.com/fonts/Fontin-Sans
    12:  http://www.fontsquirrel.com/fonts/Josefin
    13:  http://www.fontsquirrel.com/fonts/Latin-Modern-Sans
    14:  http://www.fontsquirrel.com/fonts/Liberation-Sans
    15:  http://www.fontsquirrel.com/fonts/Luxi-Sans
    16:  http://www.fontsquirrel.com/fonts/Museo-Sans
    17:  http://www.fontsquirrel.com/fonts/NotCourierSans
    18:  http://www.fontsquirrel.com/fonts/Perspective-Sans
    19:  http://www.fontsquirrel.com/fonts/PT-Sans
    20:  http://www.fontsquirrel.com/fonts/Qikki-Reg
    21:  http://www.fontsquirrel.com/fonts/Sansation
    22:  http://www.fontsquirrel.com/fonts/Sansumi
    23:  http://www.fontsquirrel.com/fonts/SouciSans
    Which one do you want? [1-23] : 

Choose the number of the font you want to install. 

The font will then be and staged to a temp directory.  The script will
then inline the ttf fonts into the webfont stylesheets so that the stylesheet
can reside on a different host than the website itself.

This script splits up the downloaded stylesheet into separate
stylesheets for each varient so that you can use them selectively.

The script will then move the font and css files to a directory for
each varient under ./public/webfonts 

To use a particular font in a project. Use the stylesheet with the
name of the font varient you want to use.

    <link rel="stylesheet" href="/webfonts/AurulentSansBoldItalic/AurulentSansBoldItalic.css" type="text/css" charset="utf-8">

    -- sample styling
    
    h1 {
      font-family: 'AurulentSansBoldItalic', Ariel, sans-serif;
    }

If you use the s3 option use the s3 url instead:

    <link rel="stylesheet" href="http://<< YOUR BUCKET NAME >>.s3.amazonaws.com/webfonts/AurulentSansBoldItalic/AurulentSansBoldItalic.css" type="text/css" charset="utf-8">


## S3

Using the --s3 option will upload the fonts to S3 for you.  You must
have the environment variables in the following section set in order
for this to work.

    thor font_squirreler:search Sans --s3

The script sets the proper headers for caching.

The fonts are stored under the directory __webfonts__ in the specified
S3 bucket.

## Cufon

Your milage may vary! I have it setup to create cufon.js files
for each of the processed fonts.  This is highly dependant upon
whether you have php, cufon and Fontforge installed.  You also
probably need to be using a Mac for this to work.

There are environment variables to set for the paths to the executables

    thor font_squirreler:search Sans --s3 --cufon

The above will generate a cufon.js file for the chosen font as well as
sending it to s3.

## Environment Variables

To use s3 you must have the following shell environment variables set.

S3_FONT_BUCKET # the name of the S3 bucket you want to store your
fonts in

AMAZON_ACCESS_KEY_ID # your amazon access key

AMAZON_SECRET_ACCESS_KEY  # your amazon secret

To use the cufont conversion:

CUFON_CONVERT_PATH # the path to the cufon convert.php executable

FONTFORGE_PATH     # the path to FontForge on a Mac defaults to /Applications/FontForge.app/Contents/MacOS/FontForge

## License

Released under the MIT License.  See the LICENSE file for further details. 
