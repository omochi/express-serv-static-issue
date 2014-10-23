# Solved!

**This issue is already solved!**

# Brunch memo

## 3.18.0

no issue. why...?

## 3.18.1

yes, no issue.

## 3.17.8

10 / 10 failed. 

# Summary

I found a bug of express and solve it.
But I have no confidence my solution is correct.
I am beginner of node.js and express.

# Issue

In this very simple static http server,
mobile safari loading progress bar is stop and some image file is not loaded.

~~~
var path = require("path");
var express = require("express");

var repoDir = path.normalize(__dirname)

var expressApp = express();
expressApp.use("/static", express.static(repoDir + "/static"));
var httpServer = expressApp.listen(3001, function() {
	console.log("Listening on port %d", httpServer.address().port);
});
~~~

Server is running on Mac, and iphone connect to it through LAN.

This is screenshot of safari.

![screenshot](https://raw.githubusercontent.com/omochi/express-serv-static-issue/master/docs/mobilesafari.png)

Loading progress bar is stopped at about 20%.
And it doesn't load all image.

# Step of Reproduce 

## environments

The case what I checked is below.

- node.js: v0.10.32

I installed it from homebrew.

## steps

In Mac (Mac book Air Mid 2013 11 inch)

~~~
$ git clone https://github.com/omochi/express-serv-static-issue.git
$ node index.js
~~~

In iPhone (iPhone 5s)

1. Terminate safari by double tap home button.
2. Settings app -> Safari -> Clear History and Website Data.
3. Open safari.
4. Connect to http://\<Mac LAN IP\>:3001/static/test.html

The issue can not be reproduce 100%.

## Occurrence Condition

By a lot of my test.
Maybe below are occurring condition of this issue.

- using mobilesafari. (chrome in iOS, safari in Mac didn't raise issue)
- loading png file by background-image css style. (img tag src attribute didn't raise issue)
- png file has alpha pixels. (non alpha png didn't raise issue)
- number of png file in page is about to 30. I tried 200 case, but issue didn't occur.

I think those condition affect safari HTTP connection handling behavior.

# Report

Below is a part of SendStream stream method.

~~~
  var stream = fs.createReadStream(path, options);
  this.emit('stream', stream);
  stream.pipe(res);

  console.log("SendStream["+path+"] res.socket = ["+res.socket+"]");
    finished = true;

  // response finished, done with the fd
  onFinished(res, function onfinished(){
  	finished = true;
  	console.log("SendStream["+path+"] onFinished: res.finished = ["+res.finished+"] , finished = ["+finished+"]");

    destroy(stream);
  });
~~~

By on-finished module implementation, if res.socket is null, onFinished will called.
So I add debug log to check res.socket.

You can confirm that below images are not loaded by checking safari screenshot.

007, 008, 009, 011, 014, 017, 020, 025, 026.

In log, some res.socket is null.

~~~
$ grep "null" docs/log.txt 
SendStream[/Users/omochi/work/github/omochi/express-serv-static-issue/static/img/007.png] res.socket = [null]
SendStream[/Users/omochi/work/github/omochi/express-serv-static-issue/static/img/008.png] res.socket = [null]
SendStream[/Users/omochi/work/github/omochi/express-serv-static-issue/static/img/009.png] res.socket = [null]
SendStream[/Users/omochi/work/github/omochi/express-serv-static-issue/static/img/011.png] res.socket = [null]
SendStream[/Users/omochi/work/github/omochi/express-serv-static-issue/static/img/014.png] res.socket = [null]
SendStream[/Users/omochi/work/github/omochi/express-serv-static-issue/static/img/013.png] res.socket = [null]
SendStream[/Users/omochi/work/github/omochi/express-serv-static-issue/static/img/015.png] res.socket = [null]
SendStream[/Users/omochi/work/github/omochi/express-serv-static-issue/static/img/017.png] res.socket = [null]
SendStream[/Users/omochi/work/github/omochi/express-serv-static-issue/static/img/020.png] res.socket = [null]
SendStream[/Users/omochi/work/github/omochi/express-serv-static-issue/static/img/019.png] res.socket = [null]
SendStream[/Users/omochi/work/github/omochi/express-serv-static-issue/static/img/021.png] res.socket = [null]
SendStream[/Users/omochi/work/github/omochi/express-serv-static-issue/static/img/022.png] res.socket = [null]
SendStream[/Users/omochi/work/github/omochi/express-serv-static-issue/static/img/023.png] res.socket = [null]
SendStream[/Users/omochi/work/github/omochi/express-serv-static-issue/static/img/024.png] res.socket = [null]
SendStream[/Users/omochi/work/github/omochi/express-serv-static-issue/static/img/025.png] res.socket = [null]
SendStream[/Users/omochi/work/github/omochi/express-serv-static-issue/static/img/026.png] res.socket = [null]
SendStream[/Users/omochi/work/github/omochi/express-serv-static-issue/static/img/028.png] res.socket = [null]
~~~

below images socket is null.

007, 008, 009, 011, 013, 014, 015, 017, 019, 020, 021, 022, 023, 024, 025, 026, 028

All not loaded images are included in socket null pattern.

Consequently I guess that file reading stream is closed before finish sending whole file bytes even if response stream is alive.
The reason why not all socket null case is failed,
nodejs stream pipeline run concurrentry and onFinish callback is called in next event loop so there are small time for sending file until process onFinish callback.


# My Solution

I modified code not to use onFinish and to use those events.

FileReadingStream error, end, ResponseStream close, finish.

## run my patch

~~~
$ export OMOCHI_PATH=1
$ node index.js
~~~
