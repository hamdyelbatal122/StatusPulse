# app-mon
[![made-with-bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/) [![powered-by-nodejs](https://img.shields.io/badge/Powered%20by%20-Node.js-brightgreen.svg)](https://nodejs.org/)

Appmon is single page web-app to monitor the health of every Tomcat applications in your organization

## How does it work?
`main.sh` script will accept `url_file` that contains list of all tomcat virtual URLs that hits `version.html` (like http://server:8080/application/version.html). Dashboard is plotted based on response (If the response is 200 OK -> green tile; if not red tile)

##  Dashboard
Output of the script will look like below :

<p align="center">
    <a href="#">
        <img src="https://raw.githubusercontent.com/iamshreeram/app-mon/master/images/AppStatus.png" />
    </a>
    <br>
</p>

## How to use

* Clone this repo 
```
git clone https://github.com/iamshreeram/app-mon.git
cd app-mon
touch config/app.conf
```
* Add the `app.conf` that contains list of all tomcat `version.html` URLs in format of `Component-name, Tomcat-Urls `
* Run the script `indexcreator.sh` to create main app monitoring page and `indexcreator.sh i` to create instance level monitoring page
* Configure the status checking functionality to run asynchronous by adding `addtile.sh` and `addtile.sh i`  in `crontab -e`
* Crontab config looks like below

> * 0 0 * * * /path-of-your-git-clone/app-mon/indexcreator.sh
> * 0 0 * * * /path-of-your-git-clone/app-mon/indexcreator.sh i
> * 1,31 * * * * /path-of-your-git-clone/app-mon/addtile.sh
> * 1,31 * * * * /path-of-your-git-clone/app-mon/addtile.sh i

* This will Enable cron job to run `indexcreator.sh` every day at `00:00` and check status every `1st minutes` and `31st minutes`

## Languages
> * Shell
> * HTML, CSS, Javascript 

## Notes 
* Dashboard is based on response of `version.html`
* Script needs a HTTP server to run
* To make it simple and light weight, Addition of external libraries are avoided 
 
## Enhancements
* ~~Position of version is hard coded and script doesn't have any intelligence. Need to make it as regex~~ -> Postition is still hard coded. Currently, `xdata` is based on previous data in the `xdata.pid` file  
* ~~Need to make the `add_tile` function as asynchronous recursion. Currently, `sleep` is using lot of CPU~~ -> Done Spliting and by creating new `xdata.pid` file
* Enable to run sub-processes which can monitor the health of direct URLs
	1. ~~Create .conf file which contains list of components to be created~~ 
	2. ~~For each component in list, create a file with same name and add list of all direct URLs~~
	3. Script will create a new folder with component name and move the direct url file to created folder
	4. Copy of Script will be posted in folder and self started
	5. Script would read the urls from file and create the status tile based on direct urls
* ~~`xdata` in the script is not dependent on time. Make it a dependent variable. So that each `tile` will get created based on time of validation~~
* ~~Add Date picker, drop down to look at specific application on specific date~~
* Enable Javascript to display version of application in tooltip on mouse over of tile
* ~~Create and append a Logo on left top of dashboard~~
* ~~Use `iframe` and modularize the page based on component~~