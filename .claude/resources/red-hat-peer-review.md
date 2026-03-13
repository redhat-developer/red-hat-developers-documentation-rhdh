<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="generator" content="Asciidoctor 2.0.20">
<link rel="icon" type="image/x-icon" href="assets/img/favicon.ico">
<title>Red Hat peer review guide for technical documentation</title>
<style>
/*! normalize.css v2.1.2 | MIT License | git.io/normalize */
@import url("https://fonts.googleapis.com/css2?family=Roboto:wght@100;200;300;400;500;600;700;800;900&display=swap");
@import url(https://fonts.googleapis.com/css?family=Lato:400,700,700italic,400italic);
@import url("https://fonts.googleapis.com/css2?family=Inconsolata:wght@200;300;400;500;600;700;800;900&display=swap");

article,
aside,
details,
figcaption,
figure,
footer,
header,
hgroup,
main,
nav,
section,
summary {
    display: block
}

audio,
canvas,
video {
    display: inline-block
}

audio:not([controls]) {
    display: none;
    height: 0
}

[hidden],
template {
    display: none
}

script {
    display: none !important
}

html {
    font-family: sans-serif;
    -ms-text-size-adjust: 100%;
    -webkit-text-size-adjust: 100%;
    scroll-behavior: smooth;
}

body {
    margin: 0;
}

a {
    background: transparent;
}

a:focus {
    outline: thin dotted
}

a:active,
a:hover {
    outline: 0
}

h1 {
    font-size: 2em;
    margin: 0.67em 0
}

abbr[title] {
    border-bottom: 1px dotted
}

b,
strong {
    font-weight: bold
}

dfn {
    font-style: italic
}

hr {
    -moz-box-sizing: content-box;
    box-sizing: content-box;
    height: 0
}

mark {
    background: #ff0;
    color: #000
}

code,
kbd,
pre,
samp {
    font-family: monospace, serif;
    font-size: 1em
}

pre {
    white-space: pre-wrap
}

q {
    quotes: "\201C""\201D""\2018""\2019"
}

small {
    font-size: 80%
}

sub,
sup {
    font-size: 75%;
    line-height: 0;
    position: relative;
    vertical-align: baseline
}

sup {
    top: -0.5em
}

sub {
    bottom: -0.25em
}

img {
    border: 0
}

svg:not(:root) {
    overflow: hidden
}

figure {
    margin: 0
}

fieldset {
    border: 1px solid #c0c0c0;
    margin: 0 2px;
    padding: 0.35em 0.625em 0.75em
}

legend {
    border: 0;
    padding: 0
}

button,
input,
select,
textarea {
    font-family: inherit;
    font-size: 100%;
    margin: 0
}

button,
input {
    line-height: normal
}

button,
select {
    text-transform: none
}

button,
html input[type="button"],
input[type="reset"],
input[type="submit"] {
    -webkit-appearance: button;
    cursor: pointer
}

button[disabled],
html input[disabled] {
    cursor: default
}

input[type="checkbox"],
input[type="radio"] {
    box-sizing: border-box;
    padding: 0
}

input[type="search"] {
    -webkit-appearance: textfield;
    -moz-box-sizing: content-box;
    -webkit-box-sizing: content-box;
    box-sizing: content-box
}

input[type="search"]::-webkit-search-cancel-button,
input[type="search"]::-webkit-search-decoration {
    -webkit-appearance: none
}

button::-moz-focus-inner,
input::-moz-focus-inner {
    border: 0;
    padding: 0
}

textarea {
    overflow: auto;
    vertical-align: top
}

table {
    border-collapse: collapse;
    border-spacing: 0
}

meta.foundation-mq-small {
    font-family: "only screen and (min-width: 768px)";
    width: 768px
}

meta.foundation-mq-medium {
    font-family: "only screen and (min-width:1280px)";
    width: 1280px
}

meta.foundation-mq-large {
    font-family: "only screen and (min-width:1440px)";
    width: 1440px
}

*,
*:before,
*:after {
    -moz-box-sizing: border-box;
    -webkit-box-sizing: border-box;
    box-sizing: border-box
}

html,
body {
    font-size: 100%
}

body {
    background: #fff;
    color: #222;
    padding: 0;
    margin: 0;
    font-family: "Helvetica Neue", "Helvetica", Helvetica, Arial, sans-serif;
    font-weight: normal;
    font-style: normal;
    line-height: 1;
    position: relative;
    cursor: auto
}

a:hover {
    cursor: pointer
}

img,
object,
embed {
    max-width: 100%;
    height: auto
}

object,
embed {
    height: 100%
}

img {
    -ms-interpolation-mode: bicubic
}

#map_canvas img,
#map_canvas embed,
#map_canvas object,
.map_canvas img,
.map_canvas embed,
.map_canvas object {
    max-width: none !important
}

.left {
    float: left !important
}

.right {
    float: right !important
}

.text-left {
    text-align: left !important
}

.text-right {
    text-align: right !important
}

.text-center {
    text-align: center !important
}

.text-justify {
    text-align: justify !important
}

.hide {
    display: none
}

.antialiased {
    -webkit-font-smoothing: antialiased
}

img {
    display: inline-block;
    vertical-align: middle
}

textarea {
    height: auto;
    min-height: 50px
}

select {
    width: 100%
}

p.lead {
    font-size: 1.21875em;
    line-height: 1.6
}

.subheader,
.admonitionblock td.content>.title,
.audioblock>.title,
.exampleblock>.title,
.imageblock>.title,
.listingblock>.title,
.literalblock>.title,
.stemblock>.title,
.openblock>.title,
.paragraph>.title,
.quoteblock>.title,
table.tableblock>.title,
.verseblock>.title,
.videoblock>.title,
.dlist>.title,
.olist>.title,
.ulist>.title,
.qlist>.title,
.hdlist>.title {
    line-height: 1.4;
    color: #222;
    font-weight: 300;
    margin-top: 0.2em;
    margin-bottom: 0.5em
}

div,
dl,
dt,
dd,
ul,
ol,
li,
h1,
h2,
h3,
#toctitle,
.sidebarblock>.content>.title,
h4,
h5,
h6,
pre,
form,
p,
blockquote,
th,
td {
    margin: 0;
    padding: 0;
    direction: ltr;
}

div.title {
    font-weight: bold !important;
}

a {
    color: #2980b9;
    text-decoration: none;
    line-height: inherit
}

a:hover,
a:focus {
    color: #3091d1
}

a img {
    border: none
}

p {
    font-family: inherit;
    font-weight: normal;
    font-size: 1em;
    line-height: 1.5;
    margin-bottom: 1.25em;
    text-rendering: optimizeLegibility
}

p aside {
    font-size: 0.875em;
    line-height: 1.35;
    font-style: italic
}

h1,
h2,
h3,
#toctitle,
.sidebarblock>.content>.title,
h4,
h5,
h6 {
    font-family: "Roboto", sans-serif;
    font-weight: bold;
    font-style: normal;
    color: #465158;
    text-rendering: optimizeLegibility;
    margin-top: 1em;
    margin-bottom: 0.5em;
    line-height: 1.2125em
}

h1 small,
h2 small,
h3 small,
#toctitle small,
.sidebarblock>.content>.title small,
h4 small,
h5 small,
h6 small {
    font-size: 60%;
    color: #909ea7;
    line-height: 0
}

h1 {
    font-size: 2.125em
}

h2 {
    font-size: 1.6875em
}

h3,
#toctitle,
.sidebarblock>.content>.title {
    font-size: 1.375em
}

h4 {
    font-size: 1.125em
}

h5 {
    font-size: 1.125em
}

h6 {
    font-size: 1em
}

hr {
    border: solid #ddd;
    border-width: 1px 0 0;
    clear: both;
    margin: 1.25em 0 1.1875em;
    height: 0
}

em,
i {
    font-style: italic;
    line-height: inherit
}

strong,
b {
    font-weight: bold;
    line-height: inherit
}

small {
    font-size: 60%;
    line-height: inherit
}

code {
    font-family: "Inconsolata", "Consolas", "Deja Vu Sans Mono", "Bitstream Vera Sans Mono", monospace;
    font-weight: normal;
    color: #2980b9
}

ul,
ol,
dl {
    font-size: 1em;
    line-height: 1.5;
    margin-bottom: 1.25em;
    list-style-position: outside;
    font-family: inherit
}

ul,
ol {
    margin-left: 0
}

ul.no-bullet,
ol.no-bullet {
    margin-left: 0
}

ul li ul,
ul li ol {
    margin-left: 1.25em;
    margin-bottom: 0;
    font-size: 1em
}

ul.square li ul,
ul.circle li ul,
ul.disc li ul {
    list-style: inherit
}

ul.square {
    list-style-type: square
}

ul.circle {
    list-style-type: circle
}

ul.disc {
    list-style-type: disc
}

ul.no-bullet {
    list-style: none
}

ol li ul,
ol li ol {
    margin-left: 1.25em;
    margin-bottom: 0
}

dl dt {
    margin-bottom: 0.3em;
    font-weight: bold
}

dl dd {
    margin-bottom: 0.75em
}

abbr,
acronym {
    text-transform: uppercase;
    font-size: 90%;
    color: #000;
    border-bottom: 1px dotted #ddd;
    cursor: help
}

abbr {
    text-transform: none
}

blockquote {
    margin: 0 0 1.25em;
    padding: 0.5625em 1.25em 0 1.1875em;
    border-left: 1px solid #ddd
}

blockquote cite {
    display: block;
    font-size: 0.8125em;
    color: #748590
}

blockquote cite:before {
    content: "\2014 \0020"
}

blockquote cite a,
blockquote cite a:visited {
    color: #748590
}

blockquote,
blockquote p {
    line-height: 1.5;
    color: #909ea7
}

.vcard {
    display: inline-block;
    margin: 0 0 1.25em 0;
    border: 1px solid #ddd;
    padding: 0.625em 0.75em
}

.vcard li {
    margin: 0;
    display: block
}

.vcard .fn {
    font-weight: bold;
    font-size: 0.9375em
}

.vevent .summary {
    font-weight: bold
}

.vevent abbr {
    cursor: auto;
    text-decoration: none;
    font-weight: bold;
    border: none;
    padding: 0 0.0625em
}

@media only screen and (min-width: 768px) {

    h1,
    h2,
    h3,
    #toctitle,
    .sidebarblock>.content>.title,
    h4,
    h5,
    h6 {
        line-height: 1.4
    }

    h1 {
        font-size: 2.75em
    }

    h2 {
        font-size: 2.3125em
    }

    h3,
    #toctitle,
    .sidebarblock>.content>.title {
        font-size: 1.6875em
    }

    h4 {
        font-size: 1.4375em
    }
}

table {
    background: #fff;
    margin-bottom: 1.25em;
    border: solid 0 #ddd
}

table thead,
table tfoot {
    background: none;
    font-weight: bold
}

table thead tr th,
table thead tr td,
table tfoot tr th,
table tfoot tr td {
    padding: 1px 8px 1px 5px;
    font-size: 1em;
    color: #222;
    text-align: left
}

table tr th,
table tr td {
    padding: 1px 8px 1px 5px;
    font-size: 1em;
    color: #222
}

table tr.even,
table tr.alt,
table tr:nth-of-type(even) {
    background: none
}

table thead tr th,
table tfoot tr th,
table tbody tr td,
table tr td,
table tfoot tr td {
    display: table-cell;
    line-height: 1.5
}

body {
    tab-size: 4;
    word-wrap: anywhere;
    font-family: "Lato", "Roboto", "Arial", "Helvetica Neue", sans-serif;
    -moz-osx-font-smoothing: grayscale;
    -webkit-font-smoothing: antialiased
}

table {
    word-wrap: normal
}

h1,
h2,
h3,
#toctitle,
.sidebarblock>.content>.title,
h4,
h5,
h6 {
    line-height: 1.4;
    padding-top: 75px;
    margin-top: -75px;
}

/* Fix the example block css */
.exampleblock>.content>h1,
.exampleblock>.content>h2,
.exampleblock>.content>h3,
.exampleblock>.content>h4,
.exampleblock>.content>h5,
.exampleblock>.content>h6 {
    line-height: 1.4;
    padding-top: unset;
    margin-top: unset;
}

object,
svg {
    display: inline-block;
    vertical-align: middle
}

.center {
    margin-left: auto;
    margin-right: auto
}

.stretch {
    width: 100%
}

.clearfix:before,
.clearfix:after,
.float-group:before,
.float-group:after {
    content: " ";
    display: table
}

.clearfix:after,
.float-group:after {
    clear: both
}

:not(pre).nobreak {
    word-wrap: normal
}

:not(pre).nowrap {
    white-space: nowrap
}

:not(pre).pre-wrap {
    white-space: pre-wrap
}

:not(pre):not([class^=L])>code {
    font-size: 0.95em;
    font-style: normal !important;
    letter-spacing: 0;
    padding: 0;
    background-color: #f2f2f2;
    -webkit-border-radius: 6px;
    border-radius: 6px;
    line-height: inherit
}

pre {
    color: inherit;
    font-family: "Consolas", "Deja Vu Sans Mono", "Bitstream Vera Sans Mono", monospace;
    line-height: 1.2
}

pre code,
pre pre {
    color: inherit;
    font-size: inherit;
    line-height: inherit
}

pre>code {
    display: block;
    padding-right: 25px;
}

pre.nowrap,
pre.nowrap pre {
    white-space: pre;
    word-wrap: normal
}

em em {
    font-style: normal
}

strong strong {
    font-weight: normal
}

.keyseq {
    color: #333
}

kbd {
    font-family: "Inconsolata", "Consolas", "Deja Vu Sans Mono", "Bitstream Vera Sans Mono", monospace;
    display: inline-block;
    color: #000;
    font-size: 0.65em;
    line-height: 1.45;
    background-color: #f7f7f7;
    border: 1px solid #ccc;
    -webkit-border-radius: 3px;
    border-radius: 3px;
    -webkit-box-shadow: 0 1px 0 rgba(0, 0, 0, 0.2), 0 0 0 0.1em #fff inset;
    box-shadow: 0 1px 0 rgba(0, 0, 0, 0.2), 0 0 0 0.1em #fff inset;
    margin: 0 0.15em;
    padding: 0.2em 0.5em;
    vertical-align: middle;
    position: relative;
    top: -0.1em;
    white-space: nowrap
}

.keyseq kbd:first-child {
    margin-left: 0
}

.keyseq kbd:last-child {
    margin-right: 0
}

.menuseq,
.menuref {
    color: #000
}

.menuseq b:not(.caret),
.menuref {
    font-weight: inherit
}

.menuseq {
    word-spacing: -0.02em
}

.menuseq b.caret {
    font-size: 1.25em;
    line-height: 0.8
}

.menuseq i.caret {
    font-weight: bold;
    text-align: center;
    width: 0.45em
}

b.button:before,
b.button:after {
    position: relative;
    top: -1px;
    font-weight: normal
}

b.button:before {
    content: "[";
    padding: 0 3px 0 2px
}

b.button:after {
    content: "]";
    padding: 0 2px 0 3px
}

#header,
#content,
#footnotes,
#footer {
    width: 100%;
    margin-left: auto;
    margin-right: auto;
    margin-top: 0;
    margin-bottom: 0;
    max-width: 62.5em;
    *zoom: 1;
    position: relative;
    padding-left: 0.9375em;
    padding-right: 0.9375em
}

#header:before,
#header:after,
#content:before,
#content:after,
#footnotes:before,
#footnotes:after,
#footer:before,
#footer:after {
    content: " ";
    display: table
}

/*#footer:before {
    vertical-align: center;
    content: url(images/redhat_standard.svg);
    width: 140px;
    font-size: 200%;
    display: flex;
    flex-direction: column;
}*/


#header:after,
#content:after,
#footnotes:after,
#footer:after {
    clear: both
}

#content {
    margin-top: 1.25em
}

#content:before {
    content: none
}

#header>h1:first-child {
    color: #111;
    margin-top: 0.1rem;
    margin-bottom: 0
}

#header>h1:first-child+#toc {
    margin-top: 8px;
    border-top: 1px solid #ddd
}

#header>h1:only-child,
body.toc2 #header>h1:nth-last-child(2) {
    border-bottom: 1px solid #ddd;
    padding-bottom: 8px
}

#header .details {
    border-bottom: 1px solid #ddd;
    line-height: 1.45;
    padding-top: 0.25em;
    padding-bottom: 0.25em;
    padding-left: 0.25em;
    color: #748590;
    display: -ms-flexbox;
    display: -webkit-flex;
    display: flex;
    -ms-flex-flow: row wrap;
    -webkit-flex-flow: row wrap;
    flex-flow: row wrap
}

#header .details span:first-child {
    margin-left: -0.125em
}

#header .details span.email a {
    color: #909ea7
}

#header .details br {
    display: none
}

#header .details br+span:before {
    content: "\00a0\2013\00a0"
}

#header .details br+span.author:before {
    content: "\00a0\22c5\00a0";
    color: #909ea7
}

#header .details br+span#revremark:before {
    content: "\00a0|\00a0"
}

#header #revnumber {
    text-transform: capitalize
}

#header #revnumber:after {
    content: "\00a0"
}

#content>h1:first-child:not([class]) {
    color: #111;
    border-bottom: 1px solid #ddd;
    padding-bottom: 8px;
    margin-top: 0;
    padding-top: 1rem;
    margin-bottom: 1.25rem
}

#toc {
    border-bottom: 1px solid #ddd;
    padding-bottom: 0.5em
}

#toc>ul {
    margin-left: 0.125em
}

#toc ul.sectlevel0>li>a {
    font-style: italic
}

#toc ul.sectlevel0 ul.sectlevel1 {
    margin: 0.5em 0
}

#toc ul {
    font-family: "Roboto", sans-serif;
    list-style-type: none
}

#toc li {
    line-height: 1.3334;
    margin-top: 0.01em
}

#toc a {
    text-decoration: none
}

#toc a:active {
    text-decoration: underline
}

#toctitle {
    color: #6c818f;
    font-size: 1.2em
}

@media only screen and (min-width: 768px) {
    #toctitle {
        font-size: 1.375em
    }

    body.toc2 {
        padding-left: 15em;
        padding-right: 0
    }

    #toc.toc2 {
        margin-top: 0 !important;
        background: #f2f2f2;
        position: fixed;
        width: 15em;
        left: 0;
        top: 0;
        border-top-width: 0 !important;
        border-bottom-width: 0 !important;
        z-index: 1000;
        padding: 1.25em 1em;
        padding-left: 3px;
        height: 100%;
        overflow: auto;
        box-shadow: 0px 0px 5px 1px rgba(0, 0, 0, 0.41);
        -webkit-box-shadow: 0px 0px 5px 1px rgba(0, 0, 0, 0.41);
    }

    #toc.toc2 #toctitle {
        margin-top: 0;
        margin-bottom: 0.8rem;
        font-size: 1.2em;
    }

    #toc.toc2>ul {
        font-size: 0.9em;
        margin-bottom: 0
    }

    #toc.toc2 ul ul {
        margin-left: 0;
        padding-left: 1em
    }

    #toc.toc2 ul.sectlevel0 ul.sectlevel1 {
        padding-left: 0;
        margin-top: 0.5em;
        margin-bottom: 0.5em
    }

    body.toc2.toc-right {
        padding-left: 0;
        padding-right: 15em
    }

    body.toc2.toc-right #toc.toc2 {
        border-right-width: 0;
        border-left: 1px solid #ddd;
        left: auto;
        right: 0
    }

    #header,
    #content,
    #footnotes,
    #footer {
        max-width: 800px;
    }

}

@media only screen and (min-width: 1280px) {
    body.toc2 {
        padding-left: 10em;
        padding-right: 0
    }

    #toc.toc2 {
        width: 20em;
    }

    #toc.toc2 #toctitle {
        font-size: 1.375em
    }

    #toc.toc2>ul {
        font-size: 0.95em
    }

    #toc.toc2 ul ul {
        padding-left: 1.25em
    }

    body.toc2.toc-right {
        padding-left: 0;
        padding-right: 20em
    }
}

#content #toc {
    border-style: solid;
    border-width: 1px;
    border-color: #d9d9d9;
    margin-bottom: 1.25em;
    padding: 1.25em;
    background: #f2f2f2;
    -webkit-border-radius: 6px;
    border-radius: 6px
}

#content #toc>:first-child {
    margin-top: 0
}

#content #toc>:last-child {
    margin-bottom: 0
}

#footer {
    background-color: #fff;
    border-top: 5px;
    padding: 1.25em
}

#footer-text {
    color: #000;
    line-height: 1.35
}

#content {
    margin-bottom: 0.625em
}

.sect1 {
    padding-bottom: 0.625em
}

@media only screen and (min-width: 768px) {
    #content {
        margin-bottom: 1.25em
    }

    .sect1 {
        padding-bottom: 1.25em
    }
}

.sect1:last-child {
    padding-bottom: 0
}

.sect1+.sect1 {
    border-top: 1px solid #ddd
}

details,
.audioblock,
.imageblock,
.literalblock,
.listingblock,
.stemblock,
.videoblock {
    margin-bottom: 1.25em
}

details>summary:first-of-type {
    cursor: pointer;
    display: list-item;
    outline: none;
    margin-bottom: 0.75em
}

.admonitionblock td.content>.title,
.audioblock>.title,
.exampleblock>.title,
.imageblock>.title,
.listingblock>.title,
.literalblock>.title,
.stemblock>.title,
.openblock>.title,
.paragraph>.title,
.quoteblock>.title,
table.tableblock>.title,
.verseblock>.title,
.videoblock>.title,
.dlist>.title,
.olist>.title,
.ulist>.title,
.qlist>.title,
.hdlist>.title {
    text-rendering: optimizeLegibility;
    text-align: left
}

table.tableblock.fit-content>caption.title {
    white-space: nowrap;
    width: 0
}

.paragraph.lead>p,
#preamble>.sectionbody>[class="paragraph"]:first-of-type p {
    font-size: 1.21875em;
    line-height: 1.6;
    color: #111
}

table.tableblock #preamble>.sectionbody>[class="paragraph"]:first-of-type p {
    font-size: inherit
}

.admonitionblock>table {
    border-collapse: separate;
    border: 0;
    background: none;
    width: 100%
}

.admonitionblock>table td.icon {
    text-align: center;
    width: 80px
}

.admonitionblock>table td.icon img {
    max-width: none
}

.admonitionblock>table td.icon .title {
    font-weight: bold;
    font-family: "Roboto", sans-serif;
    text-transform: uppercase
}

.admonitionblock>table td.content {
    padding-left: 1.125em;
    padding-right: 1.25em;
    border-left: 1px solid #ddd;
    color: #748590;
    word-wrap: anywhere
}

.admonitionblock>table td.content>:last-child>:last-child {
    margin-bottom: 0
}

.exampleblock>.content {
    border-style: solid;
    border-width: 1px;
    border-color: #e6e6e6;
    margin-bottom: 1.25em;
    padding: 1.25em;
    background: #fff;
    -webkit-border-radius: 6px;
    border-radius: 6px
}

.exampleblock>.content>:first-child {
    margin-top: 0
}

.exampleblock>.content>:last-child {
    margin-bottom: 0
}

.sidebarblock {
    border-style: solid;
    border-width: 1px;
    border-color: #d4d4d4;
    margin-bottom: 1.25em;
    padding: 1.25em;
    background: #ededed;
    -webkit-border-radius: 6px;
    border-radius: 6px
}

.sidebarblock>:first-child {
    margin-top: 0
}

.sidebarblock>:last-child {
    margin-bottom: 0
}

.sidebarblock>.content>.title {
    color: #000;
    margin-top: 0
}

.exampleblock>.content>:last-child>:last-child,
.exampleblock>.content .olist>ol>li:last-child>:last-child,
.exampleblock>.content .ulist>ul>li:last-child>:last-child,
.exampleblock>.content .qlist>ol>li:last-child>:last-child,
.sidebarblock>.content>:last-child>:last-child,
.sidebarblock>.content .olist>ol>li:last-child>:last-child,
.sidebarblock>.content .ulist>ul>li:last-child>:last-child,
.sidebarblock>.content .qlist>ol>li:last-child>:last-child {
    margin-bottom: 0
}

.literalblock pre,
.listingblock>.content>pre {
    border: 1px solid #ccc;
    -webkit-border-radius: 6px;
    border-radius: 6px;
    overflow-x: auto;
    padding: 0.5em;
    font-size: 0.8125em
}

@media only screen and (min-width: 768px) {

    .literalblock pre,
    .listingblock>.content>pre {
        font-size: 0.90625em
    }
}

@media only screen and (min-width: 1280px) {

    .literalblock pre,
    .listingblock>.content>pre {
        font-size: 0.90625em
    }
}

.literalblock pre,
.listingblock>.content>pre:not(.highlight),
.listingblock>.content>pre[class="highlight"],
.listingblock>.content>pre[class^="highlight "] {
    background: #eee
}

.literalblock.output pre {
    color: #eee;
    background-color: inherit
}

.listingblock>.content {
    position: relative
}

.listingblock code[data-lang]:before {
    display: none;
    content: attr(data-lang);
    position: absolute;
    font-size: 0.75em;
    bottom: 0.425rem;
    right: 0.5rem;
    text-transform: uppercase;
    color: inherit;
    opacity: 0.5
}

.listingblock:hover code[data-lang]:before {
    display: block
}

.listingblock.terminal pre .command:before {
    content: attr(data-prompt);
    padding-right: 0.5em;
    color: inherit;
    opacity: 0.5
}

.listingblock.terminal pre .command:not([data-prompt]):before {
    content: "$"
}

.listingblock pre.highlightjs {
    padding: 0
}

.listingblock pre.highlightjs>code {
    -webkit-border-radius: 2px;
    border-radius: 2px;
    padding: 21px;
}

.prettyprint {
    background: #eee
}

pre.prettyprint .linenums {
    line-height: 1.2;
    margin-left: 2em
}

pre.prettyprint li {
    background: none;
    list-style-type: inherit;
    padding-left: 0
}

pre.prettyprint li code[data-lang]:before {
    opacity: 1
}

pre.prettyprint li:not(:first-child) code[data-lang]:before {
    display: none
}

table.linenotable {
    border-collapse: separate;
    border: 0;
    margin-bottom: 0;
    background: none
}

table.linenotable td[class] {
    color: inherit;
    vertical-align: top;
    padding: 0;
    line-height: inherit;
    white-space: normal
}

table.linenotable td.code {
    padding-left: 0.75em
}

table.linenotable td.linenos {
    border-right: 1px solid currentColor;
    opacity: 0.35;
    padding-right: 0.5em
}

pre.pygments .lineno {
    border-right: 1px solid currentColor;
    opacity: 0.35;
    display: inline-block;
    margin-right: 0.75em
}

pre.pygments .lineno:before {
    content: "";
    margin-right: -0.125em
}

.quoteblock {
    margin: 0 1em 1.25em 1.5em;
    display: table
}

.quoteblock:not(.excerpt)>.title {
    margin-left: -1.5em;
    margin-bottom: 0.75em
}

.quoteblock blockquote,
.quoteblock p {
    color: #909ea7;
    font-size: 1.15rem;
    line-height: 1.75;
    word-spacing: 0.1em;
    letter-spacing: 0;
    font-style: italic;
    text-align: justify
}

.quoteblock blockquote {
    margin: 0;
    padding: 0;
    border: 0
}

.quoteblock blockquote:before {
    content: "\201c";
    float: left;
    font-size: 2.75em;
    font-weight: bold;
    line-height: 0.6em;
    margin-left: -0.6em;
    color: #6c818f;
    text-shadow: 0 1px 2px rgba(0, 0, 0, 0.1)
}

.quoteblock blockquote>.paragraph:last-child p {
    margin-bottom: 0
}

.quoteblock .attribution {
    margin-top: 0.75em;
    margin-right: 0.5ex;
    text-align: right
}

.verseblock {
    margin: 0 1em 1.25em 1em
}

.verseblock pre {
    font-family: "Open Sans", "DejaVu Sans", sans;
    font-size: 1.15rem;
    color: #909ea7;
    font-weight: 300;
    text-rendering: optimizeLegibility
}

.verseblock pre strong {
    font-weight: 400
}

.verseblock .attribution {
    margin-top: 1.25rem;
    margin-left: 0.5ex
}

.quoteblock .attribution,
.verseblock .attribution {
    font-size: 0.8125em;
    line-height: 1.45;
    font-style: italic
}

.quoteblock .attribution br,
.verseblock .attribution br {
    display: none
}

.quoteblock .attribution cite,
.verseblock .attribution cite {
    display: block;
    letter-spacing: -0.025em;
    color: #748590
}

.quoteblock.abstract blockquote:before,
.quoteblock.excerpt blockquote:before,
.quoteblock .quoteblock blockquote:before {
    display: none
}

.quoteblock.abstract blockquote,
.quoteblock.abstract p,
.quoteblock.excerpt blockquote,
.quoteblock.excerpt p,
.quoteblock .quoteblock blockquote,
.quoteblock .quoteblock p {
    line-height: 1.6;
    word-spacing: 0
}

.quoteblock.abstract {
    margin: 0 1em 1.25em 1em;
    display: block
}

.quoteblock.abstract>.title {
    margin: 0 0 0.375em 0;
    font-size: 1.15em;
    text-align: center
}

.quoteblock.excerpt>blockquote,
.quoteblock .quoteblock {
    padding: 0 0 0.25em 1em;
    border-left: 0.25em solid #ddd
}

.quoteblock.excerpt,
.quoteblock .quoteblock {
    margin-left: 0
}

.quoteblock.excerpt blockquote,
.quoteblock.excerpt p,
.quoteblock .quoteblock blockquote,
.quoteblock .quoteblock p {
    color: inherit;
    font-size: 1.0625rem
}

.quoteblock.excerpt .attribution,
.quoteblock .quoteblock .attribution {
    color: inherit;
    text-align: left;
    margin-right: 0
}

p.tableblock:last-child {
    margin-bottom: 0
}

td.tableblock>.content {
    margin-bottom: 1.25em;
    word-wrap: anywhere
}

td.tableblock>.content>:last-child {
    margin-bottom: -1.25em
}

table.tableblock,
th.tableblock,
td.tableblock {
    border: 0 solid #ddd
}

table.grid-all>*>tr>* {
    border-width: 0
}

table.grid-cols>*>tr>* {
    border-width: 0 0
}

table.grid-rows>*>tr>* {
    border-width: 0 0
}

table.frame-all {
    border-width: 0
}

table.frame-ends {
    border-width: 0 0
}

table.frame-sides {
    border-width: 0 0
}

table.frame-none>colgroup+*>:first-child>*,
table.frame-sides>colgroup+*>:first-child>* {
    border-top-width: 0
}

table.frame-none>:last-child>:last-child>*,
table.frame-sides>:last-child>:last-child>* {
    border-bottom-width: 0
}

table.frame-none>*>tr>:first-child,
table.frame-ends>*>tr>:first-child {
    border-left-width: 0
}

table.frame-none>*>tr>:last-child,
table.frame-ends>*>tr>:last-child {
    border-right-width: 0
}

table.stripes-all tr,
table.stripes-odd tr:nth-of-type(odd),
table.stripes-even tr:nth-of-type(even),
table.stripes-hover tr:hover {
    background: none
}

th.halign-left,
td.halign-left {
    text-align: left
}

th.halign-right,
td.halign-right {
    text-align: right
}

th.halign-center,
td.halign-center {
    text-align: center
}

th.valign-top,
td.valign-top {
    vertical-align: top
}

th.valign-bottom,
td.valign-bottom {
    vertical-align: bottom
}

th.valign-middle,
td.valign-middle {
    vertical-align: middle
}

table thead th,
table tfoot th {
    font-weight: bold
}

tbody tr th {
    display: table-cell;
    line-height: 1.5;
    background: none
}

tbody tr th,
tbody tr th p,
tfoot tr th,
tfoot tr th p {
    color: #222;
    font-weight: bold
}

p.tableblock {
    font-size: 1em
}

ol {
    margin-left: 0.25em
}

ul li ol {
    margin-left: 0
}

dl dd {
    margin-left: 1.125em
}

dl dd:last-child,
dl dd:last-child>:last-child {
    margin-bottom: 0
}

ol>li p,
ul>li p,
ul dd,
ol dd,
.olist .olist,
.ulist .ulist,
.ulist .olist,
.olist .ulist {
    margin-bottom: 0.625em
}

ul.checklist,
ul.none,
ol.none,
ul.no-bullet,
ol.no-bullet,
ol.unnumbered,
ul.unstyled,
ol.unstyled {
    list-style-type: none
}

ul.no-bullet,
ol.no-bullet,
ol.unnumbered {
    margin-left: 0.625em
}

ul.unstyled,
ol.unstyled {
    margin-left: 0
}

ul.checklist {
    margin-left: 0.625em
}

ul.checklist li>p:first-child>.fa-square-o:first-child,
ul.checklist li>p:first-child>.fa-check-square-o:first-child {
    width: 1.25em;
    font-size: 0.8em;
    position: relative;
    bottom: 0.125em
}

ul.checklist li>p:first-child>input[type="checkbox"]:first-child {
    margin-right: 0.25em
}

ul.inline {
    display: -ms-flexbox;
    display: -webkit-box;
    display: flex;
    -ms-flex-flow: row wrap;
    -webkit-flex-flow: row wrap;
    flex-flow: row wrap;
    list-style: none;
    margin: 0 0 0.625em -1.25em
}

ul.inline>li {
    margin-left: 1.25em
}

.unstyled dl dt {
    font-weight: normal;
    font-style: normal
}

ol.arabic {
    list-style-type: decimal
}

ol.decimal {
    list-style-type: decimal-leading-zero
}

ol.loweralpha {
    list-style-type: lower-alpha
}

ol.upperalpha {
    list-style-type: upper-alpha
}

ol.lowerroman {
    list-style-type: lower-roman
}

ol.upperroman {
    list-style-type: upper-roman
}

ol.lowergreek {
    list-style-type: lower-greek
}

.hdlist>table,
.colist>table {
    border: 0;
    background: none
}

.hdlist>table>tbody>tr,
.colist>table>tbody>tr {
    background: none
}

td.hdlist1,
td.hdlist2 {
    vertical-align: top;
    padding: 0 0.625em
}

td.hdlist1 {
    font-weight: bold;
    padding-bottom: 1.25em
}

td.hdlist2 {
    word-wrap: anywhere
}

.literalblock+.colist,
.listingblock+.colist {
    margin-top: -0.5em
}

.colist td:not([class]):first-child {
    padding: 0.4em 0.75em 0 0.75em;
    line-height: 1;
    vertical-align: top
}

.colist td:not([class]):first-child img {
    max-width: none
}

.colist td:not([class]):last-child {
    padding: 0.25em 0
}

.thumb,
.th {
    line-height: 0;
    display: inline-block;
    border: solid 4px #fff;
    -webkit-box-shadow: 0 0 0 1px #ddd;
    box-shadow: 0 0 0 1px #ddd
}

.imageblock.left {
    margin: 0.25em 0.625em 1.25em 0
}

.imageblock.right {
    margin: 0.25em 0 1.25em 0.625em
}

.imageblock>.title {
    margin-bottom: 0
}

.imageblock.thumb,
.imageblock.th {
    border-width: 6px
}

.imageblock.thumb>.title,
.imageblock.th>.title {
    padding: 0 0.125em
}

.image.left,
.image.right {
    margin-top: 0.25em;
    margin-bottom: 0.25em;
    display: inline-block;
    line-height: 0
}

.image.left {
    margin-right: 0.625em
}

.image.right {
    margin-left: 0.625em
}

a.image {
    text-decoration: none;
    display: inline-block
}

a.image object {
    pointer-events: none
}

sup.footnote,
sup.footnoteref {
    font-size: 0.875em;
    position: static;
    vertical-align: super
}

sup.footnote a,
sup.footnoteref a {
    text-decoration: none
}

sup.footnote a:active,
sup.footnoteref a:active {
    text-decoration: underline
}

#footnotes {
    padding-top: 0.75em;
    padding-bottom: 0.75em;
    margin-bottom: 0.625em
}

#footnotes hr {
    width: 20%;
    min-width: 6.25em;
    margin: -0.25em 0 0.75em 0;
    border-width: 1px 0 0 0
}

#footnotes .footnote {
    padding: 0 0.375em 0 0.225em;
    line-height: 1.3334;
    font-size: 0.875em;
    margin-left: 1.2em;
    margin-bottom: 0.2em
}

#footnotes .footnote a:first-of-type {
    font-weight: bold;
    text-decoration: none;
    margin-left: -1.05em
}

#footnotes .footnote:last-of-type {
    margin-bottom: 0
}

#content #footnotes {
    margin-top: -0.625em;
    margin-bottom: 0;
    padding: 0.75em 0
}

.gist .file-data>table {
    border: 0;
    background: #fff;
    width: 100%;
    margin-bottom: 0
}

.gist .file-data>table td.line-data {
    width: 99%
}

div.unbreakable {
    page-break-inside: avoid
}

.big {
    font-size: larger
}

.small {
    font-size: smaller
}

.underline {
    text-decoration: underline
}

.overline {
    text-decoration: overline
}

.line-through {
    text-decoration: line-through
}

.aqua {
    color: #00bfbf
}

.aqua-background {
    background-color: #00fafa
}

.black {
    color: #000
}

.black-background {
    background-color: #000
}

.blue {
    color: #0000bf
}

.blue-background {
    background-color: #0000fa
}

.fuchsia {
    color: #bf00bf
}

.fuchsia-background {
    background-color: #fa00fa
}

.gray {
    color: #606060
}

.gray-background {
    background-color: #7d7d7d
}

.green {
    color: #006000
}

.green-background {
    background-color: #007d00
}

.lime {
    color: #00bf00
}

.lime-background {
    background-color: #00fa00
}

.maroon {
    color: #600000
}

.maroon-background {
    background-color: #7d0000
}

.navy {
    color: #000060
}

.navy-background {
    background-color: #00007d
}

.olive {
    color: #606000
}

.olive-background {
    background-color: #7d7d00
}

.purple {
    color: #600060
}

.purple-background {
    background-color: #7d007d
}

.red {
    color: #bf0000
}

.red-background {
    background-color: #fa0000
}

.silver {
    color: #909090
}

.silver-background {
    background-color: #bcbcbc
}

.teal {
    color: #006060
}

.teal-background {
    background-color: #007d7d
}

.white {
    color: #bfbfbf
}

.white-background {
    background-color: #fafafa
}

.yellow {
    color: #bfbf00
}

.yellow-background {
    background-color: #fafa00
}

span.icon>.fa {
    cursor: default
}

a span.icon>.fa {
    cursor: inherit
}

.admonitionblock td.icon [class^="fa icon-"] {
    font-size: 2.5em;
    text-shadow: 1px 1px 1px rgba(0, 0, 0, 0.3);
    cursor: default
}

.admonitionblock td.icon .icon-note:before {
    content: "\f05a";
    color: white
}

.admonitionblock td.icon .icon-tip:before {
    content: "\f0eb";
    text-shadow: 1px 1px 2px rgba(155, 155, 0, 0.8);
    color: white
}

.admonitionblock td.icon .icon-warning:before {
    content: "\f071";
    color: white
}

.admonitionblock td.icon .icon-caution:before {
    content: "\f06d";
    color: white
}

.admonitionblock td.icon .icon-important:before {
    content: "\f06a";
    color: white
}

.conum[data-value] {
    display: inline-block;
    color: #fff !important;
    background-color: #000;
    -webkit-border-radius: 50%;
    border-radius: 50%;
    text-align: center;
    font-size: 0.75em;
    width: 1.67em;
    height: 1.67em;
    line-height: 1.67em;
    font-family: "Open Sans", "DejaVu Sans", sans-serif;
    font-style: normal;
    font-weight: bold
}

.conum[data-value] * {
    color: #fff !important
}

.conum[data-value]+b {
    display: none
}

.conum[data-value]:after {
    content: attr(data-value)
}

pre .conum[data-value] {
    position: relative;
    top: -0.125em
}

b.conum * {
    color: inherit !important
}

.conum:not([data-value]):empty {
    display: none
}

h4 {
    color: #6c818f
}

.literalblock>.content>pre,
.listingblock>.content>pre {
    -webkit-border-radius: 6px;
    border-radius: 6px;
    margin-left: 2em;
    margin-right: 2em
}

.admonitionblock {
    margin-left: 2em;
    margin-right: 2em
}

.admonitionblock>table {
    border: 1px solid #609060;
    border-top-width: 1.5em;
    background-color: #e9ffe9;
    border-collapse: separate;
    -webkit-border-radius: 0;
    border-radius: 0
}

.admonitionblock>table td.icon {
    padding-top: .5em;
    padding-bottom: .5em
}

.admonitionblock>table td.content {
    padding: .5em 1em;
    color: #000;
    font-size: .9em;
    border-left: none
}

.sidebarblock {
    background-color: #e8ecef;
    border-color: #ccc
}

.sidebarblock>.content>.title {
    color: #000
}

table.tableblock.grid-all {
    border-collapse: collapse;
    -webkit-border-radius: 0;
    border-radius: 0
}

table.tableblock.grid-all th.tableblock,
table.tableblock.grid-all td.tableblock {
    border-bottom: 1px solid #aaa
}

#footer {
    background-color: #fff;
    border-top: 2px solid #f3f3f3;
    padding: 1em
}

#footer-text {
    font-size: 0.8em;
    text-align: left;
    padding-top: 10px;
}

#toc.toc2 {
    font-family: "Lato", "Roboto", "Arial", "Helvetica Neue", sans-serif;
    padding: 0;
}

#toc.toc2 #toctitle {
    padding: 1em 1em;
    text-align: left;
    font-family: "Roboto", sans-serif;
    color: #465158;
    background: #f3f3f3;
    text-transform: uppercase;
    font-size: medium;
    border-bottom: 1px solid #dedede;
}

/*#toc.toc2 #toctitle::before {
    vertical-align: left;
    content: url(images/redhat_standard.svg);
    width: 140px;
    font-size: 200%;
    margin-left: 45px;
    display: flex;
    flex-direction: column;
}*/

#toc.toc2 a {
    display: block;
    color: #d9d9d9;
    padding: 0.25em 1em
}

#toc.toc2 a:hover,
#toc.toc2 a:focus {
    background: #dedede
}

#toc.toc2 ul {
    font-family: "Lato", "Roboto", "Arial", "Helvetica Neue", sans-serif
}

#toc.toc2 ul.sectlevel1 a {
    font-weight: bold;
    color: #465158
}

#toc.toc2 ul.sectlevel1 a {
    border-right: 3px solid transparent;
}
#toc.toc2 ul.sectlevel1 a:hover,
#toc.toc2 ul.sectlevel1 a:focus {
    color: #000;
    border-right: 3px solid #8b8b8b;
}

#toc.toc2 ul.sectlevel2,
#toc.toc2 ul.sectlevel3,
#toc.toc2 ul.sectlevel4,
#toc.toc2 ul.sectlevel5,
#toc.toc2 ul.sectlevel6 {
    padding: 0
}

#toc.toc2 ul.sectlevel2 a,
#toc.toc2 ul.sectlevel3 a,
#toc.toc2 ul.sectlevel4 a,
#toc.toc2 ul.sectlevel5 a,
#toc.toc2 ul.sectlevel6 a {
    font-weight: normal;
    color: #465158
}

#toc.toc2 ul.sectlevel2.sectlevel2 a,
#toc.toc2 ul.sectlevel3.sectlevel2 a,
#toc.toc2 ul.sectlevel4.sectlevel2 a,
#toc.toc2 ul.sectlevel5.sectlevel2 a,
#toc.toc2 ul.sectlevel6.sectlevel2 a {
    padding-left: 2em
}

#toc.toc2 ul.sectlevel2.sectlevel3 a,
#toc.toc2 ul.sectlevel3.sectlevel3 a,
#toc.toc2 ul.sectlevel4.sectlevel3 a,
#toc.toc2 ul.sectlevel5.sectlevel3 a,
#toc.toc2 ul.sectlevel6.sectlevel3 a {
    padding-left: 3em
}

#toc.toc2 ul.sectlevel2.sectlevel4 a,
#toc.toc2 ul.sectlevel3.sectlevel4 a,
#toc.toc2 ul.sectlevel4.sectlevel4 a,
#toc.toc2 ul.sectlevel5.sectlevel4 a,
#toc.toc2 ul.sectlevel6.sectlevel4 a {
    padding-left: 4em
}

#toc.toc2 ul.sectlevel2.sectlevel5 a,
#toc.toc2 ul.sectlevel3.sectlevel5 a,
#toc.toc2 ul.sectlevel4.sectlevel5 a,
#toc.toc2 ul.sectlevel5.sectlevel5 a,
#toc.toc2 ul.sectlevel6.sectlevel5 a {
    padding-left: 5em
}

#toc.toc2 ul.sectlevel2.sectlevel6 a,
#toc.toc2 ul.sectlevel3.sectlevel6 a,
#toc.toc2 ul.sectlevel4.sectlevel6 a,
#toc.toc2 ul.sectlevel5.sectlevel6 a,
#toc.toc2 ul.sectlevel6.sectlevel6 a {
    padding-left: 6em
}

:not(pre):not([class^="L"])>code {
    font-size: 0.95em;
    font-style: normal !important;
    letter-spacing: 0;
    padding: 0px 4px;
    background-color: #f6f6f6;
    -webkit-border-radius: 4px;
    border-radius: 4px;
    line-height: inherit;
    border: solid #ddd7d7 1px;
    color: #465158;
}

.admonitionblock {
    margin: 0
}

.admonitionblock.note>table {
    background-color: #e7f2fa
}

.admonitionblock.note>table td.icon {
    background-color: #3e97d7;
    width: 100%;
    text-align: left;
    padding-left: 2em
}

.admonitionblock.note>table td.icon i.icon-note::before {
    color: white
}

.admonitionblock.note>table td.icon i.icon-note::after {
    color: white;
    content: "Note";
    padding-left: 1em;
    font-family: "Lato", "Roboto", "Arial", "Helvetica Neue", sans-serif;
    font-size: 0.9em;
    font-weight: bold
}

.admonitionblock.tip>table {
    background-color: #e9ffe9
}

.admonitionblock.tip>table td.icon {
    background-color: #00b600;
    width: 100%;
    text-align: left;
    padding-left: 2em
}

.admonitionblock.tip>table td.icon i.icon-tip::before {
    color: white
}

.admonitionblock.tip>table td.icon i.icon-tip::after {
    color: white;
    content: "Tip";
    padding-left: 1em;
    font-family: "Lato", "Roboto", "Arial", "Helvetica Neue", sans-serif;
    font-size: 0.9em;
    font-weight: bold
}

.admonitionblock.caution>table {
    background-color: #ffe3ca
}

.admonitionblock.caution>table td.icon {
    background-color: #fd7700;
    width: 100%;
    text-align: left;
    padding-left: 2em
}

.admonitionblock.caution>table td.icon i.icon-caution::before {
    color: white
}

.admonitionblock.caution>table td.icon i.icon-caution::after {
    color: white;
    content: "Caution";
    padding-left: 1em;
    font-family: "Lato", "Roboto", "Arial", "Helvetica Neue", sans-serif;
    font-size: 0.9em;
    font-weight: bold
}

.admonitionblock.warning>table {
    background-color: #ffd6ca
}

.admonitionblock.warning>table td.icon {
    background-color: #fd3900;
    width: 100%;
    text-align: left;
    padding-left: 2em
}

.admonitionblock.warning>table td.icon i.icon-warning::before {
    color: white
}

.admonitionblock.warning>table td.icon i.icon-warning::after {
    color: white;
    content: "Warning";
    padding-left: 1em;
    font-family: "Lato", "Roboto", "Arial", "Helvetica Neue", sans-serif;
    font-size: 0.9em;
    font-weight: bold
}

.admonitionblock.important>table {
    background-color: #ffedcc
}

.admonitionblock.important>table td.icon {
    background-color: orange;
    width: 100%;
    text-align: left;
    padding-left: 2em
}

.admonitionblock.important>table td.icon i.icon-important::before {
    color: white
}

.admonitionblock.important>table td.icon i.icon-important::after {
    color: white;
    content: "Important";
    padding-left: 1em;
    font-family: "Lato", "Roboto", "Arial", "Helvetica Neue", sans-serif;
    font-size: 0.9em;
    font-weight: bold
}

.admonitionblock>table {
    border: none
}

.admonitionblock>table td {
    display: inline-block;
    width: 100%;
    font-size: 8px
}

.tableblock code {
    border: none;
}

.literalblock>.content>pre,
.listingblock>.content>pre {
    margin: 0
}

.literalblock pre,
.listingblock>.content>pre {
    background: #f8f8f8;
    padding: 15px;
}

@media only screen and (min-width: 768px) {
    #toc.toc2 {
        padding: 0;
        background: #f3f3f3;
    }

    /*#toc.toc2 #toctitle::before {
        margin-left: -0.5em
    }*/
}

.ulist:not(.checklist) ul,
.ulist:not(.checklist) ol {
    margin-left: 1.5em
}

/*.ulist:not(.checklist) ul li>p,
.ulist:not(.checklist) ol li>p {
    padding-left: 0.5em
}*/

.olist ol {
    margin-left: 2em
}

i.conum[data-value] {
    background-color: #465158
}

#content h1:hover>a.anchor,
#content h1>a.anchor:hover,
h2:hover>a.anchor,
h2>a.anchor:hover,
h3:hover>a.anchor,
#toctitle:hover>a.anchor,
.sidebarblock>.content>.title:hover>a.anchor,
h3>a.anchor:hover,
#toctitle>a.anchor:hover,
.sidebarblock>.content>.title>a.anchor:hover,
h4:hover>a.anchor,
h4>a.anchor:hover,
h5:hover>a.anchor,
h5>a.anchor:hover,
h6:hover>a.anchor,
h6>a.anchor:hover {
    visibility: visible
}

#content h1>a.link,
h2>a.link,
h3>a.link,
#toctitle>a.link,
.sidebarblock>.content>.title>a.link,
h4>a.link,
h5>a.link,
h6>a.link {
    color: #465158;
    text-decoration: none
}

#content h1>a.link:hover,
h2>a.link:hover,
h3>a.link:hover,
#toctitle>a.link:hover,
.sidebarblock>.content>.title>a.link:hover,
h4>a.link:hover,
h5>a.link:hover,
h6>a.link:hover {
    color: #3b444a
}

#content h1>a.link:hover:after,
h2>a.link:hover:after,
h3>a.link:hover:after,
#toctitle>a.link:hover:after,
.sidebarblock>.content>.title>a.link:hover:after,
h4>a.link:hover:after,
h5>a.link:hover:after,
h6>a.link:hover:after {
    content: "\f0c1";
    font-family: 'FontAwesome';
    font-size: 0.65em;
    display: inline-block;
    color: #3091d1;
    margin-left: 0.5em
}

/* Top navigation */
.navbar {
    background-color: #333;
    overflow: hidden;
    padding: 1em;
    position: fixed;
    width: 100%;
    top: 0;
    color: #fff !important;
    font-weight: bold;
    text-transform: uppercase;
    height: 60px;
    z-index: 9999999;
    left: 0;
    filter: drop-shadow(-3px -13px 23px #000);
    transform: translateY(-100px);
    transition: 0.4s;
}

.navbar a {
    color: #fff !important;
}

.show {
    transform: translateY(0);
}

/* Copy code */
div.content>pre>button {
    display: none;
}*

div.listingblock>div>pre.rouge>button {
    display: unset;
    border: 0;
    font-size: 0.6em;
    padding: 5px;
    text-transform: uppercase;
    font-weight: 400;
    position: absolute;
    top: 0.425rem;
    right: 0.5rem;
    background: #dedede;
    color: inherit;
    opacity: 0.5;
    border-radius: 4px;
}

/* GitHub link */
.github-corner:hover .octo-arm {
    animation: octocat-wave 560ms ease-in-out
}

@keyframes octocat-wave {
    0%,
    100% {
        transform: rotate(0)
    }

    20%,
    60% {
        transform: rotate(-25deg)
    }

    40%,
    80% {
        transform: rotate(10deg)
    }
}

/* Active TOC item tweak */
.active {
    border-right: 3px solid #2e2e2e !important;
    font-weight: bold;
    color: #465158;
    background: #dedede;
    text-decoration: none;
}

@media only screen and (max-width: 767px) {
    #toc.toc2 {
        padding: 0;
        background: #f3f3f3;
    }

    #toc.toc2 #toctitle::before {
        display: none;
    }

    #toc.toc2 #toctitle {
        display: none;
    }

    /* Top navigation */
    .navbar {
        height: 4.3em;
        font-size: 0.9em;
    }

}

@media (max-width:500px) {
    .github-corner:hover .octo-arm {
        animation: none
    }

    .github-corner .octo-arm {
        animation: octocat-wave 560ms ease-in-out
    }
}



</style>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
<meta name="viewport" content="width=device-width, height=device-height, initial-scale=1.0, maximum-scale=1.0" />
<script src="./assets/js/jquery.min.js"></script>
</head>
<body class="book toc2 toc-left">
<!-- Navbar -->
<div class="paragraph navbar">
    <p><a href="#"><span class="image"><img src="assets/img/logo.svg" alt="Home" width="30"></span> | Red Hat peer review guide for technical documentation</a>
    </p>
</div>
<div id="header">
<h1>Red Hat peer review guide for technical documentation</h1>
<div id="toc" class="toc2">
<div id="toctitle">Table of Contents</div>
<ul class="sectlevel1">
<li><a href="#introduction">Introduction</a>
<ul class="sectlevel2">
<li><a href="#about-this-guide">About this guide</a></li>
<li><a href="#purpose">Purpose of peer reviews</a></li>
</ul>
</li>
<li><a href="#checklist">Peer review checklists</a>
<ul class="sectlevel2">
<li><a href="#_language">Language</a></li>
<li><a href="#_style">Style</a></li>
<li><a href="#_minimalism">Minimalism</a></li>
<li><a href="#_structure">Structure</a></li>
<li><a href="#_usability">Usability</a></li>
</ul>
</li>
<li><a href="#providing-feedback">Providing peer review feedback</a></li>
<li><a href="#guidelines-creating-peer-review-process">Creating a peer review process</a>
<ul class="sectlevel2">
<li><a href="#considerations-creating-peer-review-process">Considerations when creating a peer review process</a></li>
<li><a href="#finalizing-team-peer-review-process">Finalizing your team&#8217;s peer review process</a></li>
<li><a href="#ref_example-peer-review-process1">Example peer review process 1</a></li>
<li><a href="#ref_example-peer-review-process2">Example peer review process 2</a></li>
</ul>
</li>
<li><a href="#pros-cons-peer-review-platforms">Appendix A: Pros and cons of the different peer review platforms</a></li>
<li><a href="#ref_an-index-of-peer-review-resources">Appendix B: Peer review resources</a></li>
</ul>
</div>
</div>
<div id="content">
<div class="sect1">
<h2 id="introduction"><a class="link" href="#introduction">Introduction</a></h2>
<div class="sectionbody">
<div class="sect2">
<h3 id="about-this-guide"><a class="link" href="#about-this-guide">About this guide</a></h3>
<div class="paragraph">
<p>This guide provides information about best practices for peer reviewing Red Hat technical documentation.</p>
</div>
<div class="paragraph">
<p>The Red Hat Customer Content Services (CCS) team created this guide for customer-facing documentation, but upstream communities that want to align more closely with the standards used by Red Hat documentation can also use this guide.</p>
</div>
</div>
<div class="sect2">
<h3 id="purpose"><a class="link" href="#purpose">Purpose of peer reviews</a></h3>
<div class="paragraph">
<p>It is recommended to perform a peer review on all updates to Red Hat documentation. Peer review provides the following benefits:</p>
</div>
<div class="ulist">
<ul>
<li>
<p>Ensuring higher quality content, which helps our users</p>
</li>
<li>
<p>Giving writers and reviewers a chance to see more content, find new ways to approach changes, and share expertise</p>
</li>
</ul>
</div>
<div class="paragraph">
<p>For peer reviews to achieve these goals, reviewers should present their comments positively and avoid negative wording. At the same time, writers must be open to reviewers' feedback. Peer reviews can catch issues that writers might miss.</p>
</div>
</div>
</div>
</div>
<div class="sect1">
<h2 id="checklist"><a class="link" href="#checklist">Peer review checklists</a></h2>
<div class="sectionbody">
<div class="paragraph">
<p>Writers and peer reviewers can use the peer review checklists as a quick reference to the Red Hat technical documentation style guidelines. Use the checklists to help structure your peer reviews, and adapt the checklists to meet the needs of your team.</p>
</div>
<div class="paragraph">
<p>For guidance on each topic outlined in the checklists, see the following resources:</p>
</div>
<div class="ulist">
<ul>
<li>
<p>IBM Style</p>
</li>
<li>
<p><a href="https://redhat-documentation.github.io/supplementary-style-guide/">Red Hat supplementary style guide for product documentation</a></p>
</li>
<li>
<p><a href="https://www.merriam-webster.com/">Merriam-Webster Dictionary</a></p>
</li>
</ul>
</div>
<div class="sect2">
<h3 id="_language"><a class="link" href="#_language">Language</a></h3>
<table class="tableblock frame-all grid-all" style="width: 75%;">
<caption class="title">Table 1. Language checklist</caption>
<colgroup>
<col style="width: 90%;">
<col style="width: 10%;">
</colgroup>
<thead>
<tr>
<th class="tableblock halign-left valign-top">Check for</th>
<th class="tableblock halign-left valign-top">Checked</th>
</tr>
</thead>
<tbody>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><strong>Spelling errors and typos</strong></p>
</div>
<div class="ulist">
<ul>
<li>
<p>American English spelling is used consistently in the text.</p>
</li>
<li>
<p>Correct punctuation is used in the text.</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">&#9744;</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><strong>Grammar</strong></p>
</div>
<div class="ulist">
<ul>
<li>
<p>American English grammar is used consistently in the text.</p>
</li>
<li>
<p>Slang or non-English words are not used in the text.</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">&#9744;</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><strong>Correct word usage and entity naming</strong></p>
</div>
<div class="ulist">
<ul>
<li>
<p>Precise wording is used. Words are used in accordance with their dictionary definitions.</p>
<div class="ulist">
<ul>
<li>
<p>The writer has also considered the context of the words, so that the meaning, tone, and implications are appropriate.</p>
</li>
</ul>
</div>
</li>
<li>
<p>Named entities are classified on first use.</p>
</li>
<li>
<p>Contractions are avoided, unless they are used intentionally for conversational style, such as in quick starts.</p>
</li>
<li>
<p>Proper nouns are capitalized.</p>
</li>
<li>
<p>Conscious language guidelines are followed. The terms <em>blacklist</em>, <em>whitelist</em>, <em>master</em>, and <em>slave</em> are used only when absolutely necessary.</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">&#9744;</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><strong>Correct use of acronyms and abbreviations</strong></p>
</div>
<div class="ulist">
<ul>
<li>
<p>Acronyms are expanded on first use.</p>
</li>
<li>
<p>Abbreviations are used and applied correctly.</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">&#9744;</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><strong>Terms and constructions</strong></p>
</div>
<div class="ulist">
<ul>
<li>
<p>Phrasal verbs are avoided.</p>
</li>
<li>
<p>Use of problematic terms such as <em>should</em> or <em>may</em> are avoided.</p>
</li>
<li>
<p>Use of anthropomorphism is avoided.</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">&#9744;</p></td>
</tr>
</tbody>
</table>
</div>
<div class="sect2">
<h3 id="_style"><a class="link" href="#_style">Style</a></h3>
<table class="tableblock frame-all grid-all" style="width: 75%;">
<caption class="title">Table 2. Style checklist</caption>
<colgroup>
<col style="width: 90%;">
<col style="width: 10%;">
</colgroup>
<thead>
<tr>
<th class="tableblock halign-left valign-top">Check for</th>
<th class="tableblock halign-left valign-top">Checked</th>
</tr>
</thead>
<tbody>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><strong>Passive voice</strong></p>
</div>
<div class="ulist">
<ul>
<li>
<p>Unnecessary use of passive voice is avoided.</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">&#9744;</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><strong>Tense</strong></p>
</div>
<div class="ulist">
<ul>
<li>
<p>Future tense is used only when necessary.</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">&#9744;</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><strong>Titles</strong></p>
</div>
<div class="ulist">
<ul>
<li>
<p>Titles use sentence case.</p>
</li>
<li>
<p>Titles and headings have consistent styling.</p>
</li>
<li>
<p>Titles are effective and descriptive.</p>
</li>
<li>
<p>Titles focus on customer tasks instead of the product.</p>
</li>
<li>
<p>Titles are 3-11 words long and have 50-80 characters.</p>
</li>
<li>
<p>Titles of procedure modules begin with a gerund, for example, "Configuring", "Using", or "Installing".</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">&#9744;</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><strong>Number</strong></p>
</div>
<div class="ulist">
<ul>
<li>
<p>Number conventions are followed.</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">&#9744;</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><strong>Formatting</strong></p>
</div>
<div class="ulist">
<ul>
<li>
<p>Content follows style and consistency guidelines for formatting, for example, user-replaceable values.</p>
</li>
<li>
<p>Content uses correct AsciiDoc markup.</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">&#9744;</p></td>
</tr>
</tbody>
</table>
</div>
<div class="sect2">
<h3 id="_minimalism"><a class="link" href="#_minimalism">Minimalism</a></h3>
<table class="tableblock frame-all grid-all" style="width: 75%;">
<caption class="title">Table 3. Minimalism checklist</caption>
<colgroup>
<col style="width: 90%;">
<col style="width: 10%;">
</colgroup>
<thead>
<tr>
<th class="tableblock halign-left valign-top">Check for</th>
<th class="tableblock halign-left valign-top">Checked</th>
</tr>
</thead>
<tbody>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><strong>Customer focus and action orientation</strong></p>
</div>
<div class="ulist">
<ul>
<li>
<p>Content focuses on actions and customer tasks.</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">&#9744;</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><strong>Scannability/Findability</strong></p>
</div>
<div class="ulist">
<ul>
<li>
<p>Content is easy to scan.</p>
</li>
<li>
<p>Information is easy to find.</p>
</li>
<li>
<p>Content uses bulleted lists and tables to make information easier to digest.</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">&#9744;</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><strong>Sentences</strong></p>
</div>
<div class="ulist">
<ul>
<li>
<p>Sentences are not unnecessarily long and only use the required number of words. Ensure that any long sentences cannot be shortened.</p>
</li>
<li>
<p>Sentences are concise and informative.</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">&#9744;</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><strong>Conciseness (no fluff)</strong></p>
</div>
<div class="ulist">
<ul>
<li>
<p>The text does not include unnecessary information.</p>
</li>
<li>
<p>Admonitions are used only when necessary.</p>
</li>
<li>
<p>Screenshots and diagrams are used only when necessary.</p>
</li>
<li>
<p>Content is clear, concise, precise, and unambiguous.</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">&#9744;</p></td>
</tr>
</tbody>
</table>
</div>
<div class="sect2">
<h3 id="_structure"><a class="link" href="#_structure">Structure</a></h3>
<table class="tableblock frame-all grid-all" style="width: 75%;">
<caption class="title">Table 4. Structure checklist</caption>
<colgroup>
<col style="width: 90%;">
<col style="width: 10%;">
</colgroup>
<thead>
<tr>
<th class="tableblock halign-left valign-top">Check for</th>
<th class="tableblock halign-left valign-top">Checked</th>
</tr>
</thead>
<tbody>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><strong>Structure meets modular guidelines</strong></p>
</div>
<div class="ulist">
<ul>
<li>
<p>Module types are not mixed, for example, concept and procedure information is separate.</p>
</li>
<li>
<p>Module types are used correctly.</p>
</li>
<li>
<p>Tags and entities are used correctly.</p>
</li>
<li>
<p>Modules are as self-contained as possible to facilitate reuse in other locations.</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">&#9744;</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><strong>A logical flow of information</strong></p>
</div>
<div class="ulist">
<ul>
<li>
<p>Information is provided at the right pace.</p>
</li>
<li>
<p>Information is presented in the most logical order and location.</p>
</li>
<li>
<p>Cross-references are used appropriately and only when useful.</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">&#9744;</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><strong>User stories</strong></p>
</div>
<div class="ulist">
<ul>
<li>
<p>The user goal is clear.</p>
</li>
<li>
<p>Tasks reflect the intended goal of the user.</p>
</li>
<li>
<p>Troubleshooting and error recognition steps are included where appropriate.</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">&#9744;</p></td>
</tr>
</tbody>
</table>
</div>
<div class="sect2">
<h3 id="_usability"><a class="link" href="#_usability">Usability</a></h3>
<table class="tableblock frame-all grid-all" style="width: 75%;">
<caption class="title">Table 5. Usability checklist</caption>
<colgroup>
<col style="width: 90%;">
<col style="width: 10%;">
</colgroup>
<thead>
<tr>
<th class="tableblock halign-left valign-top">Check for</th>
<th class="tableblock halign-left valign-top">Checked</th>
</tr>
</thead>
<tbody>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><strong>Content</strong></p>
</div>
<div class="ulist">
<ul>
<li>
<p>The content is appropriate for the intended audience.</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">&#9744;</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><strong>Accessibility</strong></p>
</div>
<div class="ulist">
<ul>
<li>
<p>Tables and diagrams have alternative (alt) text and are clearly labeled and explained in surrounding text.</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">&#9744;</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><strong>Links</strong></p>
</div>
<div class="ulist">
<ul>
<li>
<p>Use of inline links is minimized.</p>
</li>
<li>
<p>All the links in the document work.</p>
</li>
<li>
<p>All links are current.</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">&#9744;</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><strong>Visual continuity</strong></p>
</div>
<div class="ulist">
<ul>
<li>
<p>The content renders correctly in preview, including correct spacing, bulleted lists, and numbering.</p>
</li>
<li>
<p>Product versioning and release dates are accurate.</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">&#9744;</p></td>
</tr>
</tbody>
</table>
</div>
</div>
</div>
<div class="sect1">
<h2 id="providing-feedback"><a class="link" href="#providing-feedback">Providing peer review feedback</a></h2>
<div class="sectionbody">
<div class="paragraph">
<p>Peer reviews must be kind, helpful, and consistent among peer reviewers.</p>
</div>
<div class="ulist">
<ul>
<li>
<p><strong>Support your comments.</strong></p>
<div class="ulist">
<ul>
<li>
<p>Use documented resources, such as style guides or Red Hat writing conventions.</p>
</li>
<li>
<p>Explain the impact of the issue on the audience.</p>
</li>
<li>
<p>If you cannot find documented support, rethink the need for the comment.</p>
</li>
</ul>
</div>
</li>
<li>
<p><strong>Use a respectful tone.</strong></p>
<div class="ulist">
<ul>
<li>
<p>Pose comments as questions when you are unsure.</p>
</li>
<li>
<p>Choose your wording carefully and do not be harsh. Be concise for easy content updates. If you have a suggestion, ask the writer to "consider" your comment or state that you "suggest" something.</p>
</li>
</ul>
</div>
</li>
<li>
<p><strong>Stay within scope</strong>. Review only the new content, changed content, and content that provides necessary context.</p>
<div class="ulist">
<ul>
<li>
<p>Review content that was changed in the pull request (PR) or merge request (MR).</p>
</li>
<li>
<p>Review the preexisting section to ensure that the new or updated content fits.</p>
</li>
<li>
<p>Do not request enhancements to the content unless the content is unclear without it.</p>
</li>
<li>
<p>If you notice an issue in related content that you are not explicitly reviewing, use friendly wording to suggest changes. Some examples of appropriate language include:</p>
<div class="openblock">
<div class="content">
<div class="ulist">
<ul>
<li>
<p>"I know this was existing content, but would you mind fixing this typo while you’re in there?"</p>
</li>
<li>
<p>"I know this is out of scope for this PR, but consider looking into this in a future update."</p>
</li>
</ul>
</div>
</div>
</div>
<div class="paragraph">
<p>The writer might either address the issue now, track it as a future request, or let the peer reviewer know that they cannot apply the change.</p>
</div>
</li>
<li>
<p>For more information about scope, see <a href="#scope-examples">Scope examples</a>.</p>
</li>
</ul>
</div>
</li>
<li>
<p><strong>Understand that peer reviewers do not review for technical accuracy.</strong></p>
<div class="ulist">
<ul>
<li>
<p>Subject matter experts (SMEs) and quality engineering (QE) associates are responsible for testing and technical accuracy.</p>
</li>
<li>
<p>Peer reviewers check for issues like usability problems, style guide compliance, and unclear or missing steps in a procedure.</p>
</li>
<li>
<p>Peer reviewers do not need to understand all the technical details. The audience might be users who are already familiar with the technology. Request additional technical information as a followup and not as a requirement for the current PR or MR.</p>
</li>
<li>
<p>Some peer reviewers might be more familiar with a particular subject or know that an update can affect another area of the documentation. In these cases, provide this feedback to the writer.</p>
</li>
<li>
<p>If you are certain that information is wrong or that a command will fail, ask the contributor to check with their SME or QE. Avoid tagging their SMEs or QEs directly to ask.</p>
</li>
</ul>
</div>
</li>
<li>
<p><strong>Recognize that writers do not have to accept all your suggestions.</strong></p>
<div class="ulist">
<ul>
<li>
<p>Writers must implement mandatory peer review feedback that relates to style guides or typographical errors, but they can implement optional feedback at their discretion. If the issue does not break any rules or is not an actual typographical error or issue, let writers keep it as it is.</p>
</li>
<li>
<p>If you are merging a PR or MR and feel strongly that the writer must make a change but they disagree, speak to the writer in private. Cite style guides or vetted documentation so that they know your reasoning. Listen to their perspective. If the topic of the disagreement is not in any of the guides, consider bringing it to the team for discussion. In some cases, the guidelines might need to be updated.</p>
</li>
</ul>
</div>
</li>
<li>
<p><strong>Differentiate between required and optional changes.</strong></p>
<div class="ulist">
<ul>
<li>
<p>Required changes must be fixed before the writer can merge the PR or MR. Support your change with a reference to the relevant style guide or principle. Examples include modular docs template adherence, typographical error fixes, or product-specific guidelines.</p>
</li>
<li>
<p>Optional changes do not have to be addressed before the writer can merge the PR or MR. Use softer language, for example, "Here, it might be clearer to&#8230;&#8203;" or use a [SUGGESTION] tag to clearly indicate it to the writer. Examples: wording improvements, content relocation, and stylistic preference.</p>
</li>
<li>
<p>For more information about required versus suggested changes, see <a href="#scope-examples">Scope examples</a>.</p>
</li>
</ul>
</div>
</li>
<li>
<p><strong>Add your own suggestions for improvements</strong> for a problematic area. Do not provide vague or generic comments, such as "this doesn’t make sense."</p>
<div class="ulist">
<ul>
<li>
<p>Offer rewrites as suggestions, not something that the writer has to take word-for-word. For example, "I don’t understand this description. Did you mean&#8230;&#8203;?"</p>
</li>
<li>
<p>Avoid rewriting entire paragraphs of the writer’s content. If you find yourself doing this because multiple items in a paragraph need attention, break out your suggestions. If providing an alternative paragraph wording is necessary, ensure that you make it clear that the writer does not need to use your suggestion exactly as written.</p>
</li>
<li>
<p>If you notice a recurring issue, leave a global comment for the writer so that they know to address every instance of the issue. For example, "[GLOBAL] This typo occurs in other locations within the doc. I won&#8217;t comment on the other examples after this point, but please address all instances."</p>
</li>
</ul>
</div>
</li>
<li>
<p><strong>Provide positive feedback as well as negative</strong></p>
<div class="ulist">
<ul>
<li>
<p>If during your review you find a portion of content that you think is exceptionally well done, point that out in your feedback. For example, "This part is pretty much perfect, nicely done!"</p>
</li>
<li>
<p>This reinforces good writing habits and also makes getting reviews less daunting.</p>
</li>
</ul>
</div>
</li>
<li>
<p><strong>If the review requires a significant amount of editing or rework, pause the review and contact the writer directly to discuss.</strong></p>
<div class="ulist">
<ul>
<li>
<p>This avoids overwhelming the writer with too many comments and saves the peer reviewer’s time.</p>
</li>
<li>
<p>If the content is not ready for peer review, tell the writer and continue after it is ready.</p>
</li>
<li>
<p>Examples of when to pause a review include if the build is broken, if the content is not rendering properly, or if the content is not modularized correctly.</p>
</li>
<li>
<p>Contact the writer privately, for example, by chat, to express your concerns and provide advice on how to move forward.</p>
</li>
<li>
<p>Decide whether you have the time to work with the writer or if you need to request that they contact someone else, for example, an onboarding buddy or a senior writer.</p>
</li>
</ul>
</div>
</li>
<li>
<p><strong>Notify the writer when the review is complete.</strong></p>
<div class="ulist">
<ul>
<li>
<p>After you finish the review, notify the writer that the review is complete, so that they can start reviewing and implementing your feedback.</p>
</li>
</ul>
</div>
</li>
</ul>
</div>
<div id="scope-examples" class="paragraph">
<div class="title">Scope examples</div>
<p>Some suggested changes might improve the content but are not relevant or in the scope of the updates. The following table includes examples of changes that are in scope and required, in scope but suggested, and out of scope.</p>
</div>
<table class="tableblock frame-all grid-all stretch">
<caption class="title">Table 6. Examples of in scope and out of scope feedback</caption>
<colgroup>
<col style="width: 33.3333%;">
<col style="width: 33.3333%;">
<col style="width: 33.3334%;">
</colgroup>
<thead>
<tr>
<th class="tableblock halign-left valign-top">In scope - required</th>
<th class="tableblock halign-left valign-top">In scope - suggested</th>
<th class="tableblock halign-left valign-top">Out of scope</th>
</tr>
</thead>
<tbody>
<tr>
<td class="tableblock halign-left valign-top"><p class="tableblock">Typographical errors, grammatical issues, formatting issues</p></td>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p>Rearranging:</p>
</div>
<div class="ulist">
<ul>
<li>
<p>Moving something to the prerequisites section</p>
</li>
<li>
<p>Moving verification steps out of the ".Procedure" and into a specific ".Verification" section in the procedure module, if applicable</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">Comments on content that was not changed in the PR or MR</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p><a href="https://redhat-documentation.github.io/modular-docs/">Modular docs guidelines</a>, for example:</p>
</div>
<div class="ulist">
<ul>
<li>
<p>Adhering to the templates</p>
</li>
<li>
<p>Correct anchor ID format</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">Reviewing wording that does not sound right to the reviewer to see if it can be improved</p></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">Requesting additional details, like default values or units</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p>IBM Style Guide
 and <a href="https://redhat-documentation.github.io/supplementary-style-guide/">CCS supplementary style guide</a> guidelines, for example:</p>
</div>
<div class="ulist">
<ul>
<li>
<p>"may" to "might"</p>
</li>
<li>
<p>"Click the <strong>Save</strong> button." to "Click <strong>Save</strong>."</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">Avoiding sequences of admonitions, for example, a [NOTE] followed by an [IMPORTANT] block, especially if they are the same type of admonition</p></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">Technical accuracy, unless you know for certain something is wrong or that a command will fail</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><div class="content"><div class="paragraph">
<p>Product-specific guidelines, for example:</p>
</div>
<div class="ulist">
<ul>
<li>
<p>Prompts on terminal commands</p>
</li>
<li>
<p>Separating commands into individual code blocks</p>
</li>
<li>
<p>Sentence case in titles</p>
</li>
</ul>
</div></div></td>
<td class="tableblock halign-left valign-top"></td>
<td class="tableblock halign-left valign-top"></td>
</tr>
</tbody>
</table>
</div>
</div>
<div class="sect1">
<h2 id="guidelines-creating-peer-review-process"><a class="link" href="#guidelines-creating-peer-review-process">Creating a peer review process</a></h2>
<div class="sectionbody">
<div class="paragraph">
<p>Red Hat Customer Content Services (CCS) does not follow one definitive peer review process. Each team within CCS is different, with unique workflows, preferred tools, release cycles, and engineering team preferences that are customized to meet their product and customer requirements. Each team determines a peer review process that works for them.</p>
</div>
<div class="paragraph">
<p>Define a process so that peer reviews are used consistently throughout your team.</p>
</div>
<div class="sect2">
<h3 id="considerations-creating-peer-review-process"><a class="link" href="#considerations-creating-peer-review-process">Considerations when creating a peer review process</a></h3>
<div class="paragraph">
<p>Before you establish a peer review process that works for your team, review the following factors:</p>
</div>
<div class="ulist">
<ul>
<li>
<p><a href="#peer-review-optional-required">Is a peer review required or optional?</a></p>
</li>
<li>
<p><a href="#who-are-peer-reviewers">Who are the peer reviewers?</a></p>
</li>
<li>
<p><a href="#writer-request-review">How does a writer request a peer review?</a></p>
</li>
<li>
<p><a href="#peer-reviewer-assigned">How is the peer reviewer assigned?</a></p>
</li>
<li>
<p><a href="#level-scope-review">What is the level or scope of the peer review?</a></p>
</li>
<li>
<p><a href="#checklist-for-reviewer">Is there a checklist for the peer reviewer to follow?</a></p>
</li>
<li>
<p><a href="#platform-tools-used">What platform and tools are used to perform the review and give feedback?</a></p>
</li>
<li>
<p><a href="#expected-turnaround-time">What is the expected turnaround time?</a></p>
</li>
<li>
<p><a href="#urgent-peer-reviews-escalated">How are urgent peer reviews escalated?</a></p>
</li>
<li>
<p><a href="#peer-review-feedback-incorporated">How is peer review feedback incorporated?</a></p>
</li>
</ul>
</div>
<h4 id="peer-review-optional-required" class="discrete">Is a peer review required or optional?</h4>
<div class="paragraph">
<p>A technical writing manager, documentation program manager (DPM), or content strategist (CS) determines whether requesting a peer review is required or optional and communicates this expectation to the team.</p>
</div>
<div class="ulist">
<div class="title">Example options</div>
<ul>
<li>
<p>Require a peer review on each GitHub PR (or GitLab MR) prior to accepting the request.</p>
</li>
<li>
<p>Require a peer review in certain, defined situations.</p>
</li>
<li>
<p>Request a peer review at the writer&#8217;s discretion.</p>
</li>
</ul>
</div>
<h4 id="who-are-peer-reviewers" class="discrete">Who are the peer reviewers?</h4>
<div class="paragraph">
<p>Determine who conducts a peer review. A manager, DPM, or CS communicates this expectation to the team.</p>
</div>
<div class="ulist">
<div class="title">Example options</div>
<ul>
<li>
<p>Individuals can volunteer as peer reviewers.</p>
</li>
<li>
<p>Everyone on the team is expected to be available to review at any time.</p>
</li>
<li>
<p>Everyone participates in peer reviews and rotates being available or follows a roster.</p>
</li>
</ul>
</div>
<h4 id="writer-request-review" class="discrete">How does a writer request a peer review?</h4>
<div class="paragraph">
<p>Determine how writers request a peer review.</p>
</div>
<div class="ulist">
<div class="title">Example options</div>
<ul>
<li>
<p>Add the request details to a tracking spreadsheet.</p>
</li>
<li>
<p>Communicate with a reviewer in a Google Chat or a Slack channel.</p>
</li>
<li>
<p>Request a review through email.</p>
</li>
<li>
<p>Use GitHub or GitLab labels to mark when content is ready for review.</p>
</li>
<li>
<p>Open a Jira ticket or Bugzilla ticket with the request.</p>
</li>
<li>
<p>Contact a reviewer in the original documentation ticket.</p>
</li>
</ul>
</div>
<h4 id="peer-reviewer-assigned" class="discrete">How is the peer reviewer assigned?</h4>
<div class="paragraph">
<p>Some assignment methods might work better if the reviewers are on the same product team; others might work better for cross-product reviews. Establish a method that suits the structure and dynamic of the group of writers and reviewers that the process targets.</p>
</div>
<div class="paragraph">
<p>Writers must ensure that reviewers can access the tools needed to complete the review.</p>
</div>
<div class="ulist">
<div class="title">Example options</div>
<ul>
<li>
<p>Reviewers check a tracking spreadsheet and assign themselves.</p>
</li>
<li>
<p>Reviewers are notified for all peer review requests and assign themselves.</p>
</li>
<li>
<p>Reviewers regularly check a GitHub PR or a GitLab MR queue and assign themselves.</p>
</li>
<li>
<p>A writer contacts the reviewer.</p>
</li>
</ul>
</div>
<h4 id="level-scope-review" class="discrete">What is the level or scope of the peer review?</h4>
<div class="paragraph">
<p>Determine the level or scope of the peer review, so that the writer and reviewer have the same expectations.</p>
</div>
<div class="admonitionblock note">
<table>
<tr>
<td class="icon">
<i class="fa icon-note" title="Note"></i>
</td>
<td class="content">
<div class="paragraph">
<p>The writer is responsible for informing the peer reviewer of any essential information related to the content.</p>
</div>
</td>
</tr>
</table>
</div>
<div class="ulist">
<div class="title">Example options</div>
<ul>
<li>
<p>Perform a general review that checks for typographical errors, style guide compliance, and link checking.</p>
</li>
<li>
<p>Perform a deeper review of the content that includes checks on typographical errors and grammar, content placement or flow, structure, style guide compliance, and  consistency.</p>
</li>
</ul>
</div>
<h4 id="checklist-for-reviewer" class="discrete">Is there a checklist for the peer reviewer to follow?</h4>
<div class="paragraph">
<p>Determine which checklists and other resources the reviewer should follow.</p>
</div>
<div class="admonitionblock note">
<table>
<tr>
<td class="icon">
<i class="fa icon-note" title="Note"></i>
</td>
<td class="content">
<div class="paragraph">
<p>The writer must inform the peer reviewer of any essential information related to the content.</p>
</div>
</td>
</tr>
</table>
</div>
<div class="ulist">
<div class="title">Example options</div>
<ul>
<li>
<p>Follow the CCS peer review checklist.</p>
</li>
<li>
<p>Follow the CCS peer review checklist and a team-specific checklist.</p>
</li>
</ul>
</div>
<h4 id="platform-tools-used" class="discrete">What platform and tools are used to perform the review and give feedback?</h4>
<div class="paragraph">
<p>Determine how to share content and provide feedback.</p>
</div>
<div class="ulist">
<div class="title">Example options</div>
<ul>
<li>
<p>Draft content in a Google Doc and use the document for comments and suggestions.</p>
</li>
<li>
<p>Share a GitHub PR or GitLab MR. Reviewers can comment directly inline for each change.</p>
</li>
<li>
<p>Provide small snippets of content by email, instant messaging, or a ticket.</p>
</li>
</ul>
</div>
<div class="paragraph">
<p>For more information, see <a href="#pros-cons-peer-review-platforms">Pros and cons of the different peer review platforms</a>.</p>
</div>
<h4 id="expected-turnaround-time" class="discrete">What is the expected turnaround time?</h4>
<div class="paragraph">
<p>Determine the expected turnaround time for completing a peer review. Writers should communicate if there is any urgency or deadlines for the review.</p>
</div>
<div class="ulist">
<div class="title">Example options</div>
<ul>
<li>
<p>Reviewers check the GitHub or GitLab queue daily or twice daily.</p>
</li>
<li>
<p>Reviewers respond to a Slack or a Google Chat ping within a few hours.</p>
</li>
<li>
<p>Reviewers check a tracking spreadsheet daily.</p>
</li>
<li>
<p>Writers communicate the requested turnaround time after requesting the peer review.</p>
</li>
</ul>
</div>
<h4 id="urgent-peer-reviews-escalated" class="discrete">How are urgent peer reviews escalated?</h4>
<div class="paragraph">
<p>Determine how an unassigned peer review request is escalated if it can affect product release schedules.</p>
</div>
<div class="ulist">
<div class="title">Example options</div>
<ul>
<li>
<p>Inform a manager, DPM, or CS of the unassigned time-critical peer review so that they can escalate the peer review request or negotiate a new timeline for reviewing the content.</p>
</li>
<li>
<p>Use your peer review request channel to request an urgent peer review. Ensure you detail the tight timelines in the channel.</p>
</li>
</ul>
</div>
<h4 id="peer-review-feedback-incorporated" class="discrete">How is peer review feedback incorporated?</h4>
<div class="paragraph">
<p>Determine the expectations for addressing or incorporating feedback. Expectations become important if the writer and peer reviewer disagree on a review item.</p>
</div>
<div class="paragraph">
<p>Incorporate an escalation process into your peer review process, such as communicating in a guidelines group or requesting manager, DPM, or CS input. This way, the writer and peer reviewer can resolve any disagreement.</p>
</div>
<div class="ulist">
<div class="title">Example options</div>
<ul>
<li>
<p>Incorporate feedback at the writer&#8217;s discretion.</p>
</li>
<li>
<p>Establish a communication channel for informing the peer reviewer of the next steps.</p>
</li>
<li>
<p>Address peer review feedback and request the peer reviewer to perform a review of the revised content.</p>
</li>
</ul>
</div>
</div>
<div class="sect2">
<h3 id="finalizing-team-peer-review-process"><a class="link" href="#finalizing-team-peer-review-process">Finalizing your team&#8217;s peer review process</a></h3>
<div class="paragraph">
<p>Writers and peer reviewers must agree on the expectations for the peer review process.</p>
</div>
<div class="paragraph">
<p>Complete the following steps to finalize the peer review process:</p>
</div>
<div class="olist arabic">
<ol class="arabic">
<li>
<p>Draft a proposal for the peer review process.</p>
</li>
<li>
<p>Share the proposal with the team and set a time for the team to provide feedback.</p>
</li>
<li>
<p>Test the process to ensure that it works well for your team.</p>
</li>
<li>
<p>Document the final process wherever your team stores its resources.</p>
</li>
<li>
<p>Communicate the final process to the team and any other contributors or stakeholders.</p>
</li>
</ol>
</div>
</div>
<div class="sect2">
<h3 id="ref_example-peer-review-process1"><a class="link" href="#ref_example-peer-review-process1">Example peer review process 1</a></h3>
<div class="paragraph">
<p>The first example peer review process demonstrates how a cross-product team uses Jira tickets for communication and GitLab to perform peer reviews.</p>
</div>
<div class="paragraph">
<p>This team has a peer review squad of at least two members at any specific time. Membership of the squad rotates every week. The team maintains a peer review assignment roster in a Confluence page that lists the assigned reviewers for each week. The assignment roster is published in the Jira product dashboards, so that writers can see the assigned reviewers for the current week.</p>
</div>
<div id="example-1-peer-review-process" class="imageblock">
<div class="content">
<img src="images/example_peer_review_process1_image.png" alt="A flowchart that is a visual representation of the first example peer review process described in the following procedure">
</div>
<div class="title">Figure 1. Example 1 of a peer review process conducted through Jira and GitLab</div>
</div>
<div class="ulist">
<div class="title">Prerequisites</div>
<ul>
<li>
<p>A subject matter expert (SME) has completed a technical review.</p>
<div class="paragraph">
<p>To request and mark a technical review as complete, the writer performs the following tasks:</p>
</div>
<div class="olist loweralpha">
<ol class="loweralpha" type="a">
<li>
<p>Put a link to the MR in the <strong>Git Pull Request</strong> field in the Jira doc ticket.</p>
</li>
<li>
<p>Submit the MR for SME review.</p>
</li>
<li>
<p>Apply the SME reviewer&#8217;s feedback.</p>
</li>
<li>
<p>Update the MR in GitLab.</p>
</li>
</ol>
</div>
</li>
</ul>
</div>
<div class="olist arabic">
<div class="title">Procedure</div>
<ol class="arabic">
<li>
<p>To request a peer review, the writer performs the following tasks:</p>
<div class="olist loweralpha">
<ol class="loweralpha" type="a">
<li>
<p>Check the peer review assignment roster in the Jira product dashboard.</p>
</li>
<li>
<p>Add a comment in the Jira doc ticket to contact the assigned reviewers.</p>
<div class="admonitionblock note">
<table>
<tr>
<td class="icon">
<i class="fa icon-note" title="Note"></i>
</td>
<td class="content">
<div class="paragraph">
<p>The writer needs to contact the reviewers who are currently on duty according to the roster.</p>
</div>
</td>
</tr>
</table>
</div>
</li>
<li>
<p>Add the assigned reviewers to the <strong>Includes</strong> field in the Jira doc ticket.</p>
</li>
<li>
<p>Optional: Contact the assigned reviewers in the MR or chat.</p>
</li>
</ol>
</div>
</li>
<li>
<p>If a peer review does not start within the expected timeframe and the review deadline is jeopardized, the writer performs the following task:</p>
<div class="ulist">
<ul>
<li>
<p>Contact the assigned reviewers again to communicate the urgency of the request.</p>
<div class="admonitionblock note">
<table>
<tr>
<td class="icon">
<i class="fa icon-note" title="Note"></i>
</td>
<td class="content">
<div class="paragraph">
<p>If the review deadline is not jeopardized, the writer does not need to take any action at this point.</p>
</div>
</td>
</tr>
</table>
</div>
</li>
</ul>
</div>
</li>
<li>
<p>To complete a review, the peer reviewer performs the following tasks:</p>
<div class="olist loweralpha">
<ol class="loweralpha" type="a">
<li>
<p>Notify the other assigned reviewer that you will do the review.</p>
</li>
<li>
<p>Remove the other assigned reviewer from the <strong>Includes</strong> field in the Jira doc ticket.</p>
</li>
<li>
<p>Add review comments in the MR.</p>
</li>
<li>
<p>Notify the writer when you complete the review.</p>
</li>
</ol>
</div>
</li>
<li>
<p>To apply feedback and complete the process, the writer performs the following tasks:</p>
<div class="olist loweralpha">
<ol class="loweralpha" type="a">
<li>
<p>Apply the peer reviewer&#8217;s feedback.</p>
</li>
<li>
<p>Update the MR in GitLab.</p>
</li>
</ol>
</div>
</li>
</ol>
</div>
</div>
<div class="sect2">
<h3 id="ref_example-peer-review-process2"><a class="link" href="#ref_example-peer-review-process2">Example peer review process 2</a></h3>
<div class="paragraph">
<p>The second example peer review process demonstrates how a team uses a Slack channel for communication and GitHub to perform peer reviews. The peer review team consists of five team members at a given time. Membership of the peer review team rotates every sprint.</p>
</div>
<div id="example-2-peer-review-process" class="imageblock">
<div class="content">
<img src="images/example_peer_review_process2_image.png" alt="A flowchart that is a visual representation of the second example peer review process described in the following procedure.">
</div>
<div class="title">Figure 2. Example 2 of a peer review process conducted through Slack and GitHub</div>
</div>
<div class="olist arabic">
<div class="title">Procedure</div>
<ol class="arabic">
<li>
<p>To request a peer review, the writer performs the following tasks:</p>
<div class="olist loweralpha">
<ol class="loweralpha" type="a">
<li>
<p>Notify the peer review squad using the Slack channel.</p>
</li>
<li>
<p>Include a link to the PR in the Slack notification.</p>
</li>
<li>
<p>Specify any deadline or other special considerations in the Slack notification.</p>
</li>
</ol>
</div>
</li>
<li>
<p>If a peer review does not start within the expected timeframe and the review deadline is jeopardized, the writer performs the following task:</p>
<div class="ulist">
<ul>
<li>
<p>Contact the assigned reviewer or the peer review squad again to communicate the urgency of the request.</p>
<div class="admonitionblock note">
<table>
<tr>
<td class="icon">
<i class="fa icon-note" title="Note"></i>
</td>
<td class="content">
<div class="paragraph">
<p>If the review deadline is not jeopardized, the writer does not need to take any action at this point.</p>
</div>
</td>
</tr>
</table>
</div>
</li>
</ul>
</div>
</li>
<li>
<p>To complete a review, the peer reviewer performs the following tasks:</p>
<div class="olist loweralpha">
<ol class="loweralpha" type="a">
<li>
<p>Mark the request in Slack to indicate that you will perform the review.</p>
</li>
<li>
<p>Add review comments in the PR.</p>
</li>
<li>
<p>Notify the writer when you complete the review.</p>
</li>
</ol>
</div>
</li>
<li>
<p>To apply feedback and complete the process, the writer performs the following tasks:</p>
<div class="olist loweralpha">
<ol class="loweralpha" type="a">
<li>
<p>Apply the peer reviewer’s feedback.</p>
</li>
<li>
<p>Update the PR in GitHub.</p>
</li>
</ol>
</div>
</li>
</ol>
</div>
</div>
</div>
</div>
<div class="sect1">
<h2 id="pros-cons-peer-review-platforms"><a class="link" href="#pros-cons-peer-review-platforms">Appendix A: Pros and cons of the different peer review platforms</a></h2>
<div class="sectionbody">
<div class="paragraph">
<p>Review the following pros and cons for each platform to choose the right peer review method for your team.</p>
</div>
<h3 id="github-gitlab" class="discrete">GitHub or GitLab</h3>
<div class="ulist">
<div class="title">Pros</div>
<ul>
<li>
<p>Provides a convenient method for commenting on specific lines of content on a GitHub PR or GitLab MR</p>
</li>
<li>
<p>Includes functionality for easily adding additional reviewers</p>
</li>
<li>
<p>Includes a mechanism for multiple people to collaborate on the same PR or MR</p>
</li>
<li>
<p>Provides an easy linking functionality</p>
</li>
<li>
<p>Offers the capability for writers to incorporate feedback before the PR or MR is approved</p>
</li>
</ul>
</div>
<div class="ulist">
<div class="title">Cons</div>
<ul>
<li>
<p>Requires that you are familiar with the GitHub or GitLab UI</p>
</li>
<li>
<p>Requires that you have login credentials to comment on a PR or MR</p>
</li>
</ul>
</div>
<h3 id="google-docs" class="discrete">Google Docs</h3>
<div class="ulist">
<div class="title">Pros</div>
<ul>
<li>
<p>Includes a convenient method for commenting on specific text</p>
</li>
<li>
<p>Includes functionality for easily adding additional reviewers</p>
</li>
<li>
<p>Includes a mechanism for multiple people to collaborate on the same Google Doc</p>
</li>
<li>
<p>Provides an easy linking functionality</p>
</li>
<li>
<p>Supports copying and pasting of AsciiDoc syntax</p>
</li>
</ul>
</div>
<div class="ulist">
<div class="title">Cons</div>
<ul>
<li>
<p>Can produce unreliable formatting when copying and pasting HTML, PDF, or markup syntax content</p>
</li>
<li>
<p>Can be time consuming to copy and paste AsciiDoc content</p>
</li>
</ul>
</div>
<h3 id="email" class="discrete">Email</h3>
<div class="ulist">
<div class="title">Pros</div>
<ul>
<li>
<p>An easy tool for anyone to use</p>
</li>
<li>
<p>A historical record of the discussion</p>
</li>
</ul>
</div>
<div class="ulist">
<div class="title">Cons</div>
<ul>
<li>
<p>Can be difficult to link specific email comments to other communication channels</p>
</li>
<li>
<p>Can be slow and time consuming</p>
</li>
<li>
<p>Can be difficult to understand feedback if the content is not well structured</p>
</li>
</ul>
</div>
<h3 id="irc-google-chat-slack" class="discrete">IRC, Google Chat, or Slack</h3>
<div class="ulist">
<div class="title">Pros</div>
<ul>
<li>
<p>Provides fast communication</p>
</li>
<li>
<p>Can send instant notifications to online participants</p>
</li>
<li>
<p>Provides an opportunity for immediate discussion</p>
</li>
</ul>
</div>
<div class="ulist">
<div class="title">Cons</div>
<ul>
<li>
<p>Requires online access</p>
</li>
<li>
<p>Limits message length</p>
</li>
</ul>
</div>
<h3 id="jira-bugzilla" class="discrete">Jira or Bugzilla ticket</h3>
<div class="ulist">
<div class="title">Pros</div>
<ul>
<li>
<p>Supports collaboration and approval among multiple reviewers before any change is made</p>
</li>
<li>
<p>Sends comments to all followers of the ticket</p>
</li>
</ul>
</div>
<div class="ulist">
<div class="title">Cons</div>
<ul>
<li>
<p>Difficulty editing submitted comments</p>
</li>
<li>
<p>Not easy to provide inline comments on the ticket</p>
</li>
<li>
<p>Unwanted notification emails when there are multiple followers</p>
</li>
<li>
<p>Tedious to discuss lengthy content on a ticket</p>
</li>
<li>
<p>Limited space to add comments</p>
</li>
</ul>
</div>
</div>
</div>
<div class="sect1">
<h2 id="ref_an-index-of-peer-review-resources"><a class="link" href="#ref_an-index-of-peer-review-resources">Appendix B: Peer review resources</a></h2>
<div class="sectionbody">
<div class="paragraph _abstract">
<p>This section lists additional tools and resources available for peer reviewing documentation.</p>
</div>
<table class="tableblock frame-all grid-all stretch">
<caption class="title">Table 7. Validation tools</caption>
<colgroup>
<col style="width: 50%;">
<col style="width: 50%;">
</colgroup>
<thead>
<tr>
<th class="tableblock halign-left valign-top">Resource</th>
<th class="tableblock halign-left valign-top">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td class="tableblock halign-left valign-top"><p class="tableblock"><a href="https://github.com/redhat-documentation/newdoc">newdoc</a></p></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">A script for creating new files for a modular documentation repository. You can also use the script to <a href="https://github.com/redhat-documentation/newdoc#validating-a-file-for-red-hat-requirements">validate</a> whether a piece of content adheres to Red Hat documentation markup and structure standards.</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><p class="tableblock"><a href="https://redhat-documentation.github.io/vale-at-red-hat/docs/main/user-guide/introduction/">Vale for Red Hat documentation writers</a></p></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">A linting system that validates whether your text is compatible with Red Hat writing style.</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><p class="tableblock"><a href="https://www.ibm.com/able/toolkit/verify/">IBM Equal Access Accessibility Checker</a></p></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">A toolkit of instructions and <a href="https://www.ibm.com/able/toolkit/verify/automated">browser extensions</a> to generate automated accessibility reports.</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><p class="tableblock"><a href="https://github.com/wjdp/htmltest">htmltest</a></p></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">A test that validates whether the links in your HTML work.</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><p class="tableblock"><a href="https://www.grammarly.com/">Grammarly</a></p></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">A browser plug-in that checks your English spelling and grammar, but also helps improve your writing style.</p></td>
</tr>
</tbody>
</table>
<table class="tableblock frame-all grid-all stretch">
<caption class="title">Table 8. Style resources</caption>
<colgroup>
<col style="width: 50%;">
<col style="width: 50%;">
</colgroup>
<thead>
<tr>
<th class="tableblock halign-left valign-top">Resource</th>
<th class="tableblock halign-left valign-top">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td class="tableblock halign-left valign-top"><p class="tableblock">IBM Style Guide</p></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">The governing guide for IBM writing style, which most Red Hat documentation follows.</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><p class="tableblock"><a href="https://redhat-documentation.github.io/supplementary-style-guide/">Red Hat supplementary style guide for product documentation</a></p></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">A guide for writing documentation the Red Hat way, including style guidelines, formatting, and a glossary of terms and conventions.
Complementary to the IBM Style Guide.</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><p class="tableblock"><a href="https://docs.google.com/presentation/d/1Yeql9FrRBgKU-QlRU-nblPJ9pfZKgoKcU8SW6SQ_UqI/edit#slide=id.g1f4790d380_2_176">The Wisdom of Crowds slides</a></p></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">A slide deck on Red Hat community outreach, including the principles of minimalism in writing documentation.</p></td>
</tr>
</tbody>
</table>
<table class="tableblock frame-all grid-all stretch">
<caption class="title">Table 9. Markup resources</caption>
<colgroup>
<col style="width: 50%;">
<col style="width: 50%;">
</colgroup>
<thead>
<tr>
<th class="tableblock halign-left valign-top">Resource</th>
<th class="tableblock halign-left valign-top">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td class="tableblock halign-left valign-top"><p class="tableblock"><a href="https://redhat-documentation.github.io/asciidoc-markup-conventions/">AsciiDoc Mark-up Quick Reference for Red Hat Documentation</a></p></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">Guidelines on using the AsciiDoc markup language in Red Hat documentation projects.</p></td>
</tr>
</tbody>
</table>
<table class="tableblock frame-all grid-all stretch">
<caption class="title">Table 10. Structure resources</caption>
<colgroup>
<col style="width: 50%;">
<col style="width: 50%;">
</colgroup>
<thead>
<tr>
<th class="tableblock halign-left valign-top">Resource</th>
<th class="tableblock halign-left valign-top">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td class="tableblock halign-left valign-top"><p class="tableblock"><a href="https://redhat-documentation.github.io/modular-docs/">Modular Documentation Reference Guide</a></p></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">Instructions for creating Red Hat documentation in a modular way, with templates and examples.</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><p class="tableblock"><a href="https://www.nngroup.com/articles/chunking/">How Chunking Helps Content Processing</a></p></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">Tips for structuring your docs content in a visually comprehensible way.</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><p class="tableblock"><a href="https://antora-for-modular-docs.github.io/antora-for-modular-docs/docs/user-guide/introduction/">Starting a modular documentation Project in Antora</a></p></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">How to use the Antora toolchain to create a community documentation project.</p></td>
</tr>
</tbody>
</table>
<table class="tableblock frame-all grid-all stretch">
<caption class="title">Table 11. Methodology resources</caption>
<colgroup>
<col style="width: 50%;">
<col style="width: 50%;">
</colgroup>
<thead>
<tr>
<th class="tableblock halign-left valign-top">Resource</th>
<th class="tableblock halign-left valign-top">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td class="tableblock halign-left valign-top"><p class="tableblock"><a href="https://redhat-documentation.github.io/community-collaboration-guide/">Red Hat Community Collaboration Guide</a></p></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">Tips and best practices for Red Hat and the upstream community joining forces on documentation projects.</p></td>
</tr>
<tr>
<td class="tableblock halign-left valign-top"><p class="tableblock"><a href="https://www.youtube.com/watch?v=7iWUSetbaos">How to edit other people&#8217;s content without pissing them off</a></p></td>
<td class="tableblock halign-left valign-top"><p class="tableblock">Ingrid Towey&#8217;s talk on conducting peer reviews that inform and inspire but do not infuriate.</p></td>
</tr>
</tbody>
</table>
</div>
</div>
</div>
<div id="footer">
<div id="footer-text">
Last updated 2023-06-19 13:04:47 UTC
</div>
</div>
<!-- Nav bar -->
<script type="text/javascript">
const navbar = document.querySelector('.navbar');

let currentPosition = window.scrollY;

// Show navbar on page load
window.addEventListener("load", (event) => {
    navbar.classList.add('show');
});

// Show/hide navbar on scroll
window.addEventListener('scroll', () => {
    if (window.scrollY < currentPosition) {
        //scroll up
        navbar.classList.remove('show');
    } else {
        //scroll down
        navbar.classList.add('show');
    }
    currentPosition = window.scrollY;
});

// Hide navbar on click event
document.querySelectorAll('*')
    .forEach(element => element.addEventListener('click', event => {
        currentPosition = window.scrollY;
        navbar.classList.remove('show');
    }))
</script>

<!-- Copy code -->
<script type="text/javascript">
const copyButtonLabel = "Copy";

let blocks = document.querySelectorAll("pre");

blocks.forEach((block) => {
    // Only add button if browser supports Clipboard API
    if (navigator.clipboard) {
        let button = document.createElement("button");

        button.innerText = copyButtonLabel;
        block.appendChild(button);

        button.addEventListener("click", async () => {
            await copyCode(block, button);
        });
    }
});

async function copyCode(block, button) {
    let code = block.querySelector("code");
    let text = code.innerText;

    await navigator.clipboard.writeText(text);

    button.innerText = "Copied!";

    setTimeout(() => {
        button.innerText = copyButtonLabel;
    }, 400);
}
</script>

<!-- Highlight active TOC item -->
<script type="text/javascript">
const anchors = $('body').find('h1[id], h2[id], h3[id], h4[id], h5[id], h6[id]');

$(window).scroll(function(){
    var scrollTop = $(document).scrollTop();

    // highlight the last scrolled-to: set everything inactive first
    for (var i = 0; i < anchors.length; i++){
            $('#toc.toc2 a[href="#' + $(anchors[i]).attr('id') + '"]').removeClass('active');
    }

    // then iterate backwards, on the first match highlight it and break
    for (var i = anchors.length-1; i >= 0; i--){
        if (scrollTop > $(anchors[i]).offset().top - 75) {
            $('#toc.toc2 a[href="#' + $(anchors[i]).attr('id') + '"]').addClass('active');
            break;
        }
    }
});
</script>
</body>
</html>