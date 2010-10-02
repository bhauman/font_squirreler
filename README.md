# Font Squirreler

## Description

This is a Thor script that downloads, base64 encodes and inlines the
ttf font and then optionally stores the fonts on s3.

This is "beta but useful" or "betauseful" software.  

## Installation 

    thor install http://github.com/bhauman/font_squirreler/tree/master/font_squirreler.thor?raw=true

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

## Environment Variables

To use s3 you must have the following shell environment variables set.

S3_FONT_BUCKET # the name of the S3 bucket you want to store your
fonts in
AMAZON_ACCESS_KEY_ID # your amazon access key
AMAZON_SECRET_ACCESS_KEY  # your amazon secret

## License

Released under the MIT License.  See the LICENSE file for further details. 
