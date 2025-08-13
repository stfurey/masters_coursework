'''Comp116 support module with tools for downloading assignments, lecture notes, and exams
and submitting assignments and exams.

John Majikes Fall 2019
Original from Gary Bishop
'''

# Remove any deprecation warnings
import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)

import urllib
import os
import os.path as osp
import nbformat
import json
import ssl
import sys
import time
import hashlib
import pickle
import io
import random
import getpass
import inspect
import socket
import tempfile
from datetime import datetime, date
from datetime import timedelta

import matplotlib
import pylab # for side effects on matplotlib
import pandas as pd
import numpy as np
import IPython.display as ipd

Site = 'https://comp116fa20.cs.unc.edu/'
Version = '3.7.0'
PRECISION = 5
STATISTICS_FILENAME = 'unlocker.pickle'
COMP116_START = 'start'
COMP116_UNLOCK_START = 'start-unlock'
COMP116_REPORT = 'report'
COMP116_SUBMIT = 'submit'
COMP116_SUBMIT_EXAM = 'submit-exam'
COMP116_APPEARS_CORRECT = 'appears correct'
COMP116_LOGGER_START = 'logger starting'
COMP116_LOGGER_FAIL = 'logger failed'

DATETIME_HOUR_SECONDS =  "%Y-%m-%d-%H-%M"

# Find the empty file in Linux or Windows
empty_fn = '/dev/null'
try:
    with open(empty_fn) as fid:
       pass
except FileNotFoundError:
    empty_fn = 'nul'

################################
#
# Write statistics to the pickle file
# 
################################
def update_stats(filename, data):
    ''' Update the stats file with new information '''
    try:
       with open(filename, 'rb') as fid:
          statistics = pickle.load(fid)
    except:
       statistics = []

    statistics.append(data)

    try:
       with open(filename, 'wb') as fid:
          pickle.dump(statistics, fid)
    except:
       pass    


##############################
#
# functions for fetching files
#
##############################

ATTEMPTS = 10

class FakeInput:
   ''' Provide a way to fake the input() command '''

   def fake_input(self, prompt):
      ''' Override the input prompt with this prompt and read from the input_array '''
      print(prompt)
      return self.input_array.pop()

   def __init__(self, input_array):
       ''' Provide an array or list that will be used for input '''
       self.input_array = list(input_array)[::-1]
       self.original_input = globals()['__builtins__']['input']

   def __enter__(self):
       ''' set up the new input_array '''
       globals()['__builtins__']['input']  = self.fake_input

   def __exit__(self, type, value, tb):
       ''' reestablish the original input '''
       globals()['__builtins__']['input']  = self.original_input

def fileHash(filename):
    '''Compute the checksum to be sure the file is what we expect'''
    BLOCKSIZE = 65536
    hasher = hashlib.sha1()
    with open(filename, 'rb') as fp:
        buf = fp.read(BLOCKSIZE)
        while len(buf) > 0:
            hasher.update(buf)
            buf = fp.read(BLOCKSIZE)
    return hasher.hexdigest()

def fetchFile(url, filename, check, token):
    '''Download files to the student's working directory'''
    # make sure the destination folder (if any) exists
    dirname = osp.dirname(filename)
    if dirname and not osp.exists(dirname):
        try:
            os.makedirs(dirname)
        except:
            print('making folder for {} failed'.format(filename))
            return False

    message = ''
    for i in range(ATTEMPTS):
        try:
            filename, headers = urllib.request.urlretrieve(url + '?token=' + token, filename)
            if not check or fileHash(filename) == check:
                break
            else:
                print('checksum: File {} checksum not correct'.format(filename))
                message = 'File checksum not correct'
            
        except urllib.error.HTTPError as he:
            if he.code == 401:
                print('Error invalid token')
                return False
            else:
                print('httperror', he.code, 'for file', filename)
                message = 'HTTP Error {}'.format(he.code)

        # pause before trying again
        time.sleep(0.1 + random.random())

    else:
        print('Too many attempts to fetch file, failing')
        print(message)
        return False

    return True

def fetchAllFiles(siteURL, listname, token):
    '''Make sure the student has all the files listed'''
    listURL = urllib.parse.urljoin(siteURL, listname)
    fp = None
    message = ''
    for i in range(ATTEMPTS):
        try:
            fp = urllib.request.urlopen(listURL)
            code = fp.getcode()
            if code == 200:
                data = json.loads(fp.read().decode('utf-8'))
                break

            message = 'fetch failed, for %s with code %s' % (listname, code)
            
        except IOError:
            message = 'Cannot connect to server'

        except ValueError:
            message = 'File list appears invalid'

        time.sleep(0.1 + random.random())

    else:
        return -1, message

    # if we get here, we successfully retrieved the filelist
    count = 0
    checkedFiles = data['checkedFiles']
    for filename in checkedFiles:
        fileinfo = checkedFiles[filename]
        check = fileinfo.get('check', None)
        force = fileinfo.get('force', False)
        fileURL = urllib.parse.urljoin(siteURL, 'io/fetch.cgi/' + filename)
        if not osp.exists(filename) or (force and check != fileHash(filename)):
            print('fetching', filename)
            if not fetchFile(fileURL, filename, check, token):
                return -1, 'fetching files failed'
            count += 1

    return count, ''

def fetch2(token, section='000', *args):
    r, message = fetchAllFiles(Site, 'media/{}.downloads.json'.format(section), token)
    if r == 0:
        print('You have all the files that have been released for section {}.'.format(section))
    elif r > 0:
        print('Fetched {} files for section {}'.format(r, section))
        print('Now go back to your Dashboard tab to see any new notebooks.')
    # elif password:
    #     print('Fetch failed. Is the password correct?')
    else:
        print(message)

def setupVideo(url, width="480", height="300"):
    ''' Play a video that stops when out of focus'''

    # Set up the HTML to present the video and watch for when user clicks out of video
    html = '''
        <div id='videoDiv' tabindex="1" oneded="endedVid()" onblur="pauseVid()" onfocus="playVid()">
           <video id="myVideo" oncontextmenu="return false;"  
                  width="WIDTH" height="HEIGHT">
              <source src="URL" type="video/mp4">
           Your browser does not support HTML5 video.
           </video>
           <!-- Video Controls -->
           <div id="video-controls">
             <button type="button" id="playback-speed">1.5 Speed playback</button>
             <button type="button" id="full-screen">Full-Screen</button>
           </div>
        </div>
        <style>
           video::-webkit-media-controls {
             display:none !important;
           }
        </style>
        <script>
           function playVid() {
               console.log('playVid entered');
               var myVideo = $('#myVideo').get(0);
               console.log("comp116_last_video_viewed_length=" + myVideo.currentTime);
               myVideo.play();
           }

           function pauseVid() {
               console.log('pauseVid entered');
               var myVideo = $('#myVideo').get(0);
               console.log("comp116_last_video_viewed_length=" + myVideo.currentTime);
               IPython.notebook.kernel.execute("comp116_last_video_viewed_length=" + myVideo.currentTime);
               IPython.notebook.kernel.execute("comp116_video_duration=" + myVideo.duration);
               myVideo.pause();
           }

           function endedVid() {
               console.log('endedVid entered');
               var myVideo = $('#myVideo').get(0);
               console.log("comp116_last_video_viewed_length=" + myVideo.currentTime);
               IPython.notebook.kernel.execute("comp116_last_video_viewed_length=" + myVideo.currentTime);
               IPython.notebook.kernel.execute("comp116_video_duration=" + myVideo.duration);
           }


           // Event listener for the regular playback, fast playback, and full-screen button
           var playbackSpeedButton = document.getElementById("playback-speed");
           playbackSpeedButton.addEventListener("click", function() {
               var myVideo = $('#myVideo').get(0),
                   txt15 = '1.5 Speed playback',
                   txt20 = '2.0 Speed playback',
                   txt10 = '1.0 Speed playback',
                   txt = playbackSpeedButton.innerHTML;
               console.log('before button text is ' + txt);
               if (txt == txt15) {
                  myVideo.playbackRate = 1.5;
                  console.log('Setting button text to ' + txt20);
                  playbackSpeedButton.innerHTML = txt20;
               } else if (txt == txt20) {
                  myVideo.playbackRate = 2.0;
                  console.log('Setting button text to ' + txt10);
                  playbackSpeedButton.innerHTML = txt10;
               } else if (txt == txt10) {
                  myVideo.playbackRate = 1.0;
                  console.log('Setting button text to ' + txt15);
                  playbackSpeedButton.innerHTML = txt15;
               };
               txt = playbackSpeedButton.innerHTML;
               console.log('after button text is ' + txt);
           });
           var fullScreenButton = document.getElementById("full-screen");
           fullScreenButton.addEventListener("click", function() {
               var myVideo = $('#myVideo').get(0);
               if (myVideo.requestFullscreen) {
                   console.log('requestFullScreen');
                   myVideo.requestFullscreen();
                   myVideo.removeAttribute("controls");
                   playVid();
               } else if (myVideo.mozRequestFullScreen) {
                   console.log('mozilla mozRequestFullScreen');
                   myVideo.mozRequestFullScreen(); // Firefox
                   myVideo.removeAttribute("controls");
                   playVid();
               } else if (myVideo.webkitRequestFullscreen) {
                   console.log('webkit RequestFullScreen');
                   myVideo.webkitRequestFullscreen(); // Chrome and Safari
                   myVideo.removeAttribute("controls");
                   playVid();
               } else {
                   console.log('fullscreen else');
                   pauseVid();
               }
           });

           // Watch for a exit full screen
           document.addEventListener('fullscreenchange', exitHandler);
           document.addEventListener('webkitfullscreenchange', exitHandler);
           document.addEventListener('mozfullscreenchange', exitHandler);
           document.addEventListener('MSFullscreenChange', exitHandler);

           function exitHandler() {
               if (!document.fullscreenElement && !document.webkitIsFullScreen && !document.mozFullScreen && !document.msFullscreenElement) {
                  pauseVid();
               }
           }  
        </script>
    '''.replace('URL', url).replace('HEIGHT', height).replace('WIDTH', width)
    return ipd.display(ipd.HTML(html))

def fetch(*args):
    html = '''
        <button type="button" id="fetchButton116">Fetch your notebooks</button>
        <pre id="fetchMessages116"></pre>
        <script>
        $('#fetchButton116').on('click', function() {
            var $log = $('#fetchMessages116');
            $log.empty();
            $log.append('Login to fetch your notebooks<br>');
            $.ajax({
                url: 'SITE' + 'io/token/token.cgi',
                dataType: 'jsonp'
            }).done(function(data) {
                $log.empty().append('Fetching notebooks for ' + data.userid + ' section ' + data.section + '<br>');
                var notebook = IPython.notebook.notebook_name,
                    uuid = data.token,
                    section = data.section,
                    command = "import comp116; comp116.fetch2('" + uuid + "', '" + section +"')",
                    kernel = IPython.notebook.kernel,
                    handler = function (out) {
                        if (out.msg_type == 'stream') {
                            $log.append(out.content.text);
                        } else if(out.msg_type == "error") {
                            $log.append(out.content.ename + ": " + out.content.evalue);
                        } else { // if output is something we haven't thought of
                            $log.append("[out type not implemented]")
                        }
                    };
                if (section == "000") {
                    $log.append("The section number for " + data.userid + " has not been set!<br>");
                } else {
                    $log.append("Loading the files for section " + section + "!<br>");
                }
                kernel.execute(command, { 'iopub' : {'output' : handler}}, {silent:false});
            }).fail(function() {
                $log.append("Login failed. If you didn't get a login prompt, ensure you are online by opening a browser tab to python.org");
            });
        });
        </script>
    '''.replace('SITE', Site)
    return ipd.HTML(html)

def addGlobalVarsToFirstCell(fname, globalVars):
    ''' Given a notebook filename and a globalVars dictionary, add the globals to the
        first cell of the notebook.

        Return a binary string of the file
    '''
    try:
        nb = nbformat.read(open(fname, 'r'), 4)
    except (IOError, FileNotFoundError):
        raise UserWarning('Notebook %s not found.' % fname)

    for indx in range(len(nb['cells'])):
        if nb['cells'][indx]['cell_type'] == 'code':
            for key in globalVars:
                nb['cells'][indx]['source'] = ('{} = {}\n'.format(key, json.dumps(globalVars[key])) + 
                                                           nb['cells'][indx]['source'])
            break

    tempfname = 'eraseme' +  fname
    with open(tempfname, 'w') as bfile:
        nbformat.write(nb, bfile, 4)

    with open(tempfname, 'rb') as bfile:
        book = bfile.read()
    return tempfname, book

#############################
#
# functions for submitting notebooks
#
#############################

def pushNotebook(name, uuid,
        submitCode='',
        globalVars=json.dumps({}),
        url = 'io/submit.cgi'):
    '''Upload the notebook to our server'''
    globalVars = json.loads(globalVars)

    if not name.endswith('.ipynb'):
        fname = name + '.ipynb'
    else:
        fname = name

    tempfname, book = addGlobalVarsToFirstCell(fname, globalVars)
    check = fileHash(tempfname)
    os.remove(tempfname)
    try:
        assignment = expected['_assignment']
    except KeyError:
        raise UserWarning('Missing assignment, you must run your notebook before submitting it.')

    data = {
        'filename': name,
        'book': book,
        'token': uuid,
        'assignment': assignment,
        'check': check,
        'modified': datetime.fromtimestamp(osp.getmtime(fname)),
        'now': datetime.now(),
        'submitCode': submitCode
    }

    # timeout in seconds
    timeout = 10
    socket.setdefaulttimeout(timeout)

    postdata = urllib.parse.urlencode(data)
    postdata = postdata.encode('UTF-8') # data should be bytes
    req = urllib.request.Request(Site + url, postdata)
    # try to post it to the server
    for i in range(10):
        try:
            resp = urllib.request.urlopen(req)
        except urllib.error.URLError:
            raise
            break
        except urllib.error.HTTPError as e:
            print(e)
            raise
        if resp.getcode() == 200:
            break
        if resp.getcode() == 206:
            raise UserWarning('The submit code {} was not accepted'.format(submitCode))
        time.sleep(0.1 * i)
    else:
        code = resp.getcode()
        msg = resp.read()
        raise UserWarning('upload failed code={} msg="{}"'.format(code, msg))

#############################
#
# functions for submitting pickle files
#
#############################

def json_serial(obj):
    '''JSON serializer for objects not serializable by default json code'''
    if isinstance(obj, (datetime, date)):
       return obj.isoformat()
def pushPickle(fname, uuid,
        url = 'io/pickle.cgi'):
    '''Upload the pickle file to our server'''

    try:
        with open(fname, 'rb') as fid:
           book = json.dumps(pickle.load(fid), default=json_serial)
    except IOError:
        # Silently ignore
        return
    try:
        assignment = expected['_assignment'] 
    except KeyError:
        raise UserWarning('Missing assignment, you must run your notebook before submitting it.')

    data = {
        'filename': fname,
        'book': book,
        'token': uuid,
        'assignment': assignment,
        'modified': datetime.fromtimestamp(osp.getmtime(fname)),
        'now': datetime.now(),
    }

    # timeout in seconds
    timeout = 10
    socket.setdefaulttimeout(timeout)

    postdata = urllib.parse.urlencode(data)
    postdata = postdata.encode('UTF-8') # data should be bytes
    req = urllib.request.Request(Site + url, postdata)
    # try to post it to the server
    for i in range(10):
        try:
            resp = urllib.request.urlopen(req)
        except urllib.error.URLError:
            raise
            break
        except urllib.error.HTTPError as e:
            print(e)
            raise
        if resp.getcode() == 200:
            break
        time.sleep(0.1 * i)
    else:
        code = resp.getcode()
        msg = resp.read()
        raise UserWarning('upload failed code={} msg="{}"'.format(code, msg))

def pushJSON(fname, uuid,
        url = 'io/json.cgi'):
    '''Upload the xxx_log.json file to our server'''

    try:
        with open(fname, 'r') as fid:
            # book  = fid.read()
            book = json.load(fid)
    except IOError as e:
        # Silently ignore
        return
    try:
        assignment = expected['_assignment']
    except KeyError:
        raise UserWarning('Missing assignment, you must run your notebook before submitting it.')

    data = {
        'filename': fname,
        'book': book,
        'token': uuid,
        'assignment': assignment,
        'modified': datetime.fromtimestamp(osp.getmtime(fname)),
        'now': datetime.now(),
    }

    # timeout in seconds
    timeout = 10
    socket.setdefaulttimeout(timeout)

    postdata = urllib.parse.urlencode(data)
    postdata = postdata.encode('UTF-8') # data should be bytes
    req = urllib.request.Request(Site + url, postdata)
    # try to post it to the server
    for i in range(10):
        try:
            resp = urllib.request.urlopen(req)
        except urllib.error.URLError:
           raise
           break
        except urllib.error.HTTPError as e:
            print(e)
            raise
        if resp.getcode() == 200:
            break
        time.sleep(0.1 * i)
    else:
        code = resp.getcode()
        msg = resp.read()
        raise UserWarning('upload failed code={} msg="{}"'.format(code, msg))

#############################
#
# functions for submitting questions
#
#############################
class CustomErrorForDebugging(Exception):
   def __init__(self, arg):
      self.msg = 'DebugMsg:' + arg

def pushQuestion(question, uuid,
        url = 'io/postQuestion.cgi'):
    '''Submit a question to the front of class '''

    data = {
        'question': question,
        'token': uuid,
        'uploaded': str(datetime.now())
    }

    postdata = urllib.parse.urlencode(data)
    postdata = postdata.encode('UTF-8') # data should be bytes
    req = urllib.request.Request(Site + url, postdata) 
    # try to post it to the server
    for i in range(10):
        try:
            resp = urllib.request.urlopen(req)
        except urllib.error.URLError as e:
            # raise CustomErrorForDebugging(str(e.reason) + '\n' + str(data) + '\n' + Site + url)
            raise
            break
        except urllib.error.HTTPError as e:
            print(e)
            raise
        if resp.getcode() == 200:
            break
        time.sleep(0.1 * i)
    else:
        code = resp.getcode()
        msg = resp.read()
        raise UserWarning('upload failed code={} msg="{}"'.format(code, msg))

def showSubmitButton(notebook=None, needSubmitCode=False, globalVars=json.dumps({})):
    '''Generate code to diplay the submit button in the notebook'''
    if notebook:
        notebook = "'" + notebook + "'"
    else:
        notebook = 'IPython.notebook.notebook_name'

    html = '''
<p>Click the button below to submit your notebook. 
Watch for a confirmation message that your notebook was successfully uploaded. 
</p>
<p>If you are prompted for a submit code, you must enter a valid submit code shown
on the screen in the front of class for the submission to be accepted.
</p>
You may submit as often as you wish.
Early submissions may receive bonus points and late submissions may receive penalty points
(see the syallabus for more details).
But your grade will be the submission with the most points.
</p>
<button id="submitButton116">Submit notebook NOTEBOOK</button>
<p id="submitResponse116"></p>
<script>
var site = 'SITE';
var notebook = NOTEBOOK;
var needSubmitCode = NEEDSUBMITCODE;
var globalVars = 'GLOBALVARS';
document.getElementById("submitButton116").innerHTML = "Submit notebook " + notebook;
$('#submitButton116').on('click', function() {
    var site = 'SITE',
        $sresp = $('#submitResponse116'),
        button = $('#submitButton116');
    button.prop('disabled', true);
    // wait until save is complete before pushing the notebook
    $([IPython.events]).one('notebook_saved.Notebook', function() {
        // get the token by logging in
        $sresp.html('logging in');
        $.ajax({
            url: site + 'io/token/token.cgi',
            dataType: 'jsonp'
        }).done(function(data) {

            // Push the json log
            $sresp.append('Logging');
            var notebook = NOTEBOOK + '_log.json',
                uuid = data.token,
                command = "comp116.pushJSON('" + notebook + "', '" + uuid + "')",
                kernel = IPython.notebook.kernel,
                handler = function (out) {
                };
            kernel.execute(command, {shell: { reply: handler }});

            // Get submit code if needed, '' otherwise
            if (needSubmitCode) {
               submitCode = prompt("Enter the submit code displayed at the front of the class : ", "xxxx");
               if (submitCode == null) {
                  submitCode = '';
               }
            } else {
               submitCode = '';
            }
            var notebook = 'unlocker.pickle',
                uuid = data.token,
                command = "comp116.pushPickle('" + notebook + "', '" + uuid + "')",
                kernel = IPython.notebook.kernel,
                handler = function (out) {
                };
            $sresp.html('Setting up');
            kernel.execute(command, {shell: { reply: handler }});
            var notebook = NOTEBOOK,
                uuid = data.token,
                command = "comp116.pushNotebook('" + notebook + "', '" + uuid + "', '" + submitCode + "', globalVars='" + globalVars + "')",
                kernel = IPython.notebook.kernel,
                handler = function (out) {
                    $('#comp116-stop-message').show();
                    if (out.content.status == "ok") {
                        $sresp.html("Successfully submitted " + notebook);
                        $('#comp116-stop-message').hide();
                    } else if(out.content.status == "error") {
                        $sresp.html(out.content.ename + ": " + out.content.evalue);
                    } else { // if output is something we haven't thought of
                        $sresp.html("[out type not implemented]")
                    }
                    button.prop('disabled', false);
                };
            $sresp.html('Submitting');
            kernel.execute(command, {shell: { reply: handler }});
        }).fail(function() {
            $sresp.html("Login failed. If you didn't get a login prompt, ensure you are online by opening a browser tab to python.org");
            if (! navigator.onLine) {
               $sresp.html('Browser offline');
            }
            button.prop('disabled', false);
        });
    });
    // trigger the save
    $sresp.html('Saving');
    IPython.notebook.save_notebook();
});'''.replace('SITE', Site).replace('NOTEBOOK', notebook).replace('NEEDSUBMITCODE', str(needSubmitCode).lower()).replace('GLOBALVARS', str(globalVars))
    return ipd.HTML(html)

def recordAttendance(notebook='Attendance'):
    ''' Submit the attendance notebook '''
    needSubmitCode = True

    html = '''
<p>Click the button below to record your attendance.  Watch for a confirmation message
that your notebook was successfully uploaded. </p>
<button id="attendanceButton116">Record NOTEBOOK</button>
<p id="attendanceResponse116"></p>
<script>
var site = 'SITE';
var notebook = 'NOTEBOOK';
var needSubmitCode = NEEDSUBMITCODE;
document.getElementById("attendanceButton116").innerHTML = "Record " + notebook;
$('#attendanceButton116').on('click', function() {
    var site = 'SITE',
        notebook = 'NOTEBOOK',
        $sresp = $('#attendanceResponse116'),
        button = $('#attendanceButton116');
    button.prop('disabled', true);
    // wait until save is complete before pushing the notebook
    $([IPython.events]).one('notebook_saved.Notebook', function() {
        // get the token by logging in
        $sresp.html('logging in');
        $.ajax({
            url: site + 'io/token/token.cgi',
            dataType: 'jsonp'
        }).done(function(data) {
            // Get submit code if needed, '' otherwise
            if (needSubmitCode) {
               submitCode = prompt("Enter the submit code displayed at the front of the class : ", "xxxx");
               if (submitCode == null) {
                  submitCode = '';
               }
            } else {
               submitCode = '';
            }
            var notebook = 'NOTEBOOK',
                uuid = data.token,
                command = "comp116.expected.update( {'_assignment': 'NOTEBOOK'}) ; comp116.pushNotebook('" + notebook + "', '" + uuid + "', '" + submitCode + "')",
                kernel = IPython.notebook.kernel,
                handler = function (out) {
                    $('#comp116-stop-message').show();
                    if (out.content.status == "ok") {
                        $sresp.html("Successfully submitted " + notebook);
                        $('#comp116-stop-message').hide();
                    } else if(out.content.status == "error") {
                        $sresp.html(out.content.ename + ": " + out.content.evalue);
                    } else { // if output is something we haven't thought of
                        $sresp.html("[out type not implemented]")
                    }
                    button.prop('disabled', false);
                };
            $sresp.html('Submitting');
            kernel.execute(command, {shell: { reply: handler }});
        }).fail(function() {
            $sresp.html("Login failed. If you didn't get a login prompt, ensure you are online by opening a browser tab to python.org");
            if (! navigator.onLine) {
               $sresp.html('Browser offline');
            }
            button.prop('disabled', false);
        });
    });
    // trigger the save
    $sresp.html('Saving');
    IPython.notebook.save_notebook();
});'''.replace('SITE', Site).replace('NOTEBOOK', notebook).replace('NEEDSUBMITCODE', str(needSubmitCode).lower())
    return ipd.HTML(html)

##################################################
#
# functions for checking student answers
#
##################################################

def check_function(tag, func, *args, **kwargs):
    if not callable(func):
        print(tag, 'not a function')
        return
    try:
        no_globals(func)
    except AssertionError:
        print(tag, 'incorrect use of global variables')
        return
    try:
        result = func(*args)
    except:
        print(tag, 'function produces an error')
        raise

    check(tag, result, **kwargs)

def check_array(tag, given, ev, extra):
    '''Compare arrays and array-like things'''
    rtol = 10.0 ** -extra.get('precision', PRECISION)
    if not isinstance(given, np.ndarray):
        try:
            given = np.array(given)
        except:
            print("Answer for check '{}' is incorrect".format(tag))
            if ((not expected.get('_quiz', False)) and
                (not expected.get('_exam', False))):
                print("  expected 'array-like'")
            return 0.0

    if given.shape != ev.shape:
        print("Answer for check '{}' is the incorrect shape".format(tag))
        print('  expected', ev.shape, 'got', given.shape)
        return 0.0

    if issubclass(ev.dtype.type, np.number):
        if issubclass(given.dtype.type, np.number):
            if not np.allclose(given, ev, rtol=rtol):
                print(tag, 'incorrect values in array')
                return 0.0
        else:
            print(tag, 'incorrect array type', given.dtype.type)
            print('  expected', ev.dtype.type)
            return 0.0

    else:
        try:
            if not np.all(ev == given):
                print(tag, 'incorrect values in array')
                return 0.0
        except:
            print(tag, 'incorrect array value')
            return 0.0

    return 1.0

def normalize_y(yh):
    '''normalize bar graph y with a row of minimums and a row of maximums'''
    y0 = yh[0]
    y1 = y0 + yh[1]
    ys = np.array([y0, y1])
    ymin = np.min(ys, axis=0)
    ymax = np.max(ys, axis=0)
    return np.array([ymin, ymax])

def check_bars(tag, given, expected, rtol=1e-6, atol=1e-8):
    '''Compare bar graphs'''
    if given.shape[-1] != expected.shape[-1]:
        print(tag, 'Wrong number of bars')
        return 0
    if not np.allclose(given[0], expected[0], rtol=rtol, atol=atol):
        print(tag, 'X values incorrect')
        return 0
    gy = normalize_y(given[1:])
    ey = normalize_y(expected[1:])
    if not np.allclose(gy, ey, rtol=rtol, atol=atol):
        print(tag, 'Y values incorrect')
        return 0
    return 1

def check_figure(tag, given, ev, extra):
    '''Compare a few features of figures'''
    rtol = extra.get('relative_tolerance', 1e-5)
    atol = extra.get('absolute_tolerance', 1e-8)
    given = figureState(given)
    LabelScore = 0.0
    LabelWeight = 0.0
    for attr in ['title', 'xlabel', 'ylabel']:
        if ev[attr]:
            LabelWeight += 1
            if ev[attr] != given[attr]:
                print("Answer for check '{}' {} is incorrect".format(tag, attr))
                print('  expected', ev[attr])
            else:
                LabelScore += 1
    if LabelWeight > 0:
        LabelScore /= LabelWeight
        LabelWeight = 1.0

    # compare line graphs
    LineWeight = 0.0
    nlines = len(ev['lines'])
    LOK = np.zeros(nlines)
    if nlines:
        LineWeight = 1.0
        glines = len(given['lines'])
        for i in range(glines):
            gline = given['lines'][i]
            for j in range(nlines):
                if not LOK[j]:
                    eline = ev['lines'][j]
                    try:
                       LOK[j] = (len(eline[0]) == len(gline[0]) and
                           len(eline[1]) == len(gline[1]) and
                           np.allclose(eline[0], gline[0], rtol=rtol, atol=atol) and
                           np.allclose(eline[1], gline[1], rtol=rtol, atol=atol))
                    except TypeError as e:
                        print('For line {} there is a type error'.format(e))
                        print(e)
                        LOK[j] = 0
                    if LOK[j]:
                        break

        LineScore = np.mean(LOK)

        if LineScore == 0:
            print(tag, 'values of plotted lines incorrect')
        elif LineScore < 1.0:
            print(tag, 'values of some lines incorrect')
    else:
        LineScore = 0

    if LineScore > 0 and glines > nlines:
        print(tag, 'too many lines')
        LineScore *= float(nlines) / glines

    # compare bar charts
    BarWeight = 0.0
    nbars = ev['bars'].shape[1]
    if nbars:
        BarWeight = 1.0
        BarScore = check_bars(tag, given['bars'], ev['bars'], rtol=rtol, atol=atol)

    else:
        BarScore = 0

    Score = (LabelScore + LineScore + BarScore) / float(LabelWeight + LineWeight + BarWeight)
    return Score

def check_char(tag, given, ev, extra):
    '''Compare a character '''
    if not isinstance(given, (char)):
        print("Answer for check '{}' is incorrect".format(tag))
        print(" expected char")
        return 0.0
    OK = (given == ev)
    if not OK:
        print("Answer for check '{}' is incorrect".format(tag))
        print("  expected '{}'".format(ev))
    return float(OK)

def check_float(tag, given, ev, extra):
    '''Compare floats for approximate equality'''
    rtol = 10.0 ** -extra.get('precision', PRECISION)
    if not isinstance(given, (float, int)):
        print("Answer for check '{}' is incorrect".format(tag))
        print(" expected float")
        return 0.0
    OK = np.allclose(given, ev, rtol=rtol)
    if not OK:
        print("Answer for check '{}' is incorrect".format(tag))
        print("  expected '{}'".format(ev))
    return float(OK)

try:
    from grading import record_grade
except ImportError:
    def record_grade(expected):
        pass

try:
    from solution import start, check, report
except ImportError as e:
    pass

    # contains the expected answers
    expected = {}


    def test_online(host='8.8.8.8', port=53, timeout=1):
        '''Test to see if the user is online'''
        try:
            socket.setdefaulttimeout(timeout)
            socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect((host, port))
            return True
        except Exception as ex:
            return False

    def start(assignment, unlocker=False, section=0, logger=True):
        '''Initialize expected values for checking a student submission'''
        pname = assignment + '.pickle'
        if sys.version[:len(Version)] != Version:
           print("Warning: You are not running Anaconda version %s" % Version)
           print("Warning: Your Anacond aversion is:\n%s" % sys.version)
        expected.update(pickle.load(open(pname, 'rb')))
        if not expected.get('_remote', False) and expected.get('_exam', False) and time.time() - osp.getmtime(pname) < 3 * 60 * 60:
            expected['_monitor'] = True

        if unlocker:
           update_stats(STATISTICS_FILENAME, {'name': COMP116_UNLOCK_START,
                                              'now': datetime.now(),
                                              'status': 'Starting {}'.format(assignment)})
        else:   
           update_stats(STATISTICS_FILENAME, {'name': COMP116_START,
                                              'now': datetime.now(),
                                              'status': 'Starting {}'.format(assignment)})
    
        expected['_section'] = section
        if logger:
           try:
               import logger
               logger.start(assignment + '.ipynb', True)
               update_stats(STATISTICS_FILENAME, {'name': COMP116_LOGGER_START,
                                                  'now': datetime.now(),
                                                  'status': 'Starting'})
           except Exception as e:
               update_stats(STATISTICS_FILENAME, {'name': COMP116_LOGGER_FAIL,
                                                  'now': datetime.now(),
                                                  'status': e})
            
        return check, report

    def check(tag, val, *args, **kwargs):
        '''Provide feedback on a single value'''
        stats_status = kwargs.get('stats_status', '')

        # Sort value but don't update caller's copy
        if kwargs.get('sorted', False):
            value = sorted(val)
        else:
            value = val
        if expected.get('_monitor') and test_online():
            pass
#             stats_status += 'You appear online\n'
#             ipd.display(ipd.HTML('''
# <p style="background:crimson;height:8em;display:flex;align-items:center">
# You appear to be online.  Disable wireless before continuing. %s</p>''' % datetime.now().isoformat())) 
        assert tag in expected
        e = expected[tag]
            
        dv = describe_answer(value)
        score = 1.0
        
        if e['description'] != dv:
            # Don't give correctness indication on quizzes
            print("Answer for check '{}' is incorrect".format(tag))
            print("your answer is of type '{}'".format(dv))
            if ((not expected.get('_quiz', False)) and
                (not expected.get('_exam', False))):
               print("expected answer is '{}'".format(e['description']))
            score = 0.0
            stats_status += 'incorrect type. Your type: {}. Expected type: {}\n'.format(
               dv, e['description'])
            
        elif callable(value):
            try:
                no_globals(value)
            except AssertionError:
                score = 0.0
                print('incorrect use of global variables')
                stats_status += 'incorrect use of global variables\n'
            else:
                e['correct'] = 1.0
                # Don't give correctness indication on quizzes
                print(tag, 'function signature appears correct')
                value = value(*args)
                stats_status += 'function signature appears correct\n'
                update_stats(STATISTICS_FILENAME, {'name': 'check' + tag,
                                                   'now': datetime.now(),
                                                   'status': stats_status})
                return check(tag, value, stats_status=stats_status, **kwargs)
            
        elif 'hash' in e and 'value' not in e:
            # Exams have hash expected values but no actual values
            hv = hash_answer(value, kwargs.get('precision', PRECISION))
            if hv != e['hash']:
                score = 0.0
                print("Answer for check '{}' is incorrect".format(tag))
                stats_status += 'incorrect\n'
                
        else:
            ev = e['value']
            extra = e['extra']

            if isinstance(ev, np.ndarray):
                score = check_array(tag, value, ev, extra)

            elif isinstance(ev, dict) and 'FigureState' in ev:
                score = check_figure(tag, value, ev, extra)

            elif isinstance(ev, float):
                score = check_float(tag, value, ev, extra)

            elif value == ev:
                pass

            else:
                print("Answer for check '{}' is incorrect".format(tag))
                # Only give expected value if it's not a quiz and not an exam
                if ((not expected.get('_quiz', False)) and
                    (not expected.get('_exam', False))):
                   print("  expected '{}'".format(ev))
                score = 0.0
                stats_status += 'incorrect expected {}\n'.format(ev)


        # Don't give correctness indication on quizzes
        if score == 1.0:
            print("Answer for check '{}' {}".format(tag, COMP116_APPEARS_CORRECT))
            stats_status += COMP116_APPEARS_CORRECT
        elif score > 0:
            print("Answer for check '{}' {}".format(tag, 'partially correct'))
            stats_status += 'partially correct'

        e['correct'] = score
        update_stats(STATISTICS_FILENAME, {'name': 'check' + tag,
                                           'now': datetime.now(),
                                           'status': stats_status})
        
    def tagSort(tags):
        return sorted(tags,
            key=lambda tag: ''.join([ s.isdigit() and '%02d'%int(s) or s
                              for s in re.findall(r'\d+|\D+', tag)
                              ]))

    def report(author, extra):
        '''Summarize the student's performance'''
        stats_status = ''
        expected['_score'] = 0.0
        correct = 0
        problems = 0
        answered = 0
        points = 0
        max_points = 0
        for tag in tagSort(expected.keys()):
            if tag.startswith('_'):
                continue
            if (expected['_section'] != 0 and     # Staff report
                expected[tag]['section'] != 0 and # Not tagged all sections
                expected[tag]['section'] != expected['_section']): # Not tagged for this section
                # This tag is not for this report
                continue
            problems += 1
            c = expected[tag]['correct']

            if c > 0:
                correct += c
                points += expected[tag]['points'] * c
                if c < 1:
                    print("Answer for check '{}' is partially incorrect".format(tag))
                    stats_status += 'partially incorrect\n'
                else:
                    print("Answer for check '{}' {}".format(tag, COMP116_APPEARS_CORRECT),
                            '' if (expected['_section'] or not expected[tag]['section']) else 'for section {}'.format(expected[tag]['section'])
                          )
                    stats_status += COMP116_APPEARS_CORRECT + '\n'
            else:
                print("Answer for check '{}' is incorrect".format(tag))
            max_points += expected[tag]['points']
        print("Report:")

        if '_exam' in expected and expected['_exam']:
            if not extra:
                print('You must type your name as the value of the pledge variable before you can submit your work.', file=sys.stderr)
                stats_status += 'Must type your name\n'
                update_stats(STATISTICS_FILENAME, {'name': COMP116_REPORT,
                                                   'now': datetime.now(),
                                                   'status': stats_status})
                expected['_score'] = 0
                record_grade(expected)
                return
            else:
                print("  Pledged on my honor:", extra)
                print("   ", getpass.getuser())

        print("  {} of {} possibly correct for up to {} of {} points".format(correct, problems, points, max_points))
        expected['_score'] = points
        
        record_grade(expected)
        update_stats(STATISTICS_FILENAME, {'name': COMP116_REPORT,
                                           'now': datetime.now(),
                                           'status': stats_status})

        # If this is an exam, don't show the submit button
        if '_exam' not in expected or not expected['_exam']:
            return showSubmitButton()

def submit(ws):
    expected['_assignment'] = ws
    update_stats(STATISTICS_FILENAME, {'name': COMP116_SUBMIT,
                                       'now': datetime.now(),
                                       'status': 'submit'.format(assignment)})
    return showSubmitButton()

def submitExam(filename, needSubmitCode=None, globalVars=json.dumps({})):

    if '_assignment' in expected:
        assignment = expected['_assignment']
    else:
        assignment = filename

    if needSubmitCode is None:
       if ((assignment[0] == 'Q') or
           (assignment[0:7] == 'Midterm') or
           (assignment == 'FE')):
          needSubmitCode = True
       else:
          needSubmitCode = False
    if not test_online():
       print('You appear to be offline!')
    update_stats(STATISTICS_FILENAME, {'name': COMP116_SUBMIT_EXAM,
                                       'now': datetime.now(),
                                       'status': 'submit {} globalVars={}'.format(assignment, globalVars)})
    return showSubmitButton(filename, needSubmitCode, globalVars)
    
def no_globals(*funcs):
    '''Warn about global variables in functions, a common source of problems'''
    import inspect
    NoGlobalVars = True
    for func in funcs:
        for gname, gvalue in inspect.getclosurevars(func).globals.items():
            if (not inspect.ismodule(gvalue) and 
                not isinstance(gvalue, matplotlib.figure.Figure) and
                not inspect.isclass(gvalue) and
                not inspect.isfunction(gvalue)):
                print('Warning: You appear to be using global variable "{}" in function "{}"'
                    .format(gname, func.__name__))
                NoGlobalVars = False
    assert NoGlobalVars, 'Use only parameters and local variables in your functions'

def test_no_globals(fn):
    try:
       no_globals(fn)
       return True
    except AssertionError:
       return False

def figureState(f):
    '''Extract interesting bits of the state out of a figure'''
    s = {
        'FigureState':True,
        'title': '',
        'xlabel': '',
        'ylabel': '',
        'lines': [],
        'bars' : np.zeros((3, 0)),
    }
    try:
        axis = f.axes[0]
        s['title'] = axis.title.get_text()
        s['xlabel'] = axis.xaxis.label.get_text()
        s['ylabel'] = axis.yaxis.label.get_text()
        s['lines'] = [(line.get_xdata(), line.get_ydata())
                      for line in axis.lines]
        xbars = [p.get_x() for p in axis.patches]
        ybars = [p.get_y() for p in axis.patches]
        hbars = [p.get_height() for p in axis.patches]
        s['bars'] = np.array([xbars, ybars, hbars])
    except:
        pass
    return s

from collections import OrderedDict
import re

def describe_answer(o):
    '''Hack to describe the type of an object in English'''
    def wrap(d):
        '''Enclose description in parenthesis if it contains comma or and.'''
        if ', ' in d or ' and ' in d:
            return '(' + d + ')'
        else:
            return d

    def and_list(items):
        '''comma separated list with and at the end'''
        if len(items) <= 2:
            return " and ".join(items)
        return ", ".join(items[ : -1]) + ", and " + items[-1]

    def describe_sequence(o, typ, memo):
        '''describe a list or tuple'''
        if len(o) == 0:
            return 'empty ' + typ
        if id(o) in memo:
            return '[...]'
        memo.add(id(o))
        et = [ wrap(describe_any(e, memo)) for e in o ]
        uet = list(OrderedDict.fromkeys(et))
        if len(uet) == 1:
            et = '{} {}'.format(len(et), uet[0])
        else:
            et = and_list(et)
        return typ + ' of ' + et
    
    def describe_dict(o, memo):
        if len(o) == 0:
            return 'empty dict'
        if id(o) in memo:
            return '{...}'
        memo.add(id(o))
        it = [ (describe_any(k, memo) + ':' + wrap(describe_any(v, memo))) for k,v in sorted(o.items()) ]
        uit = list(OrderedDict.fromkeys(it))
        if len(uit) == 1:
            it = '{} {}'.format(len(o), uit[0])
        else:
            it = and_list(it)
        return 'dictionary of {}'.format(it)
    
    def describe_set(o, memo):
        if len(o) == 0:
            return 'empty set'
        if id(o) in memo:
            return '{...}'
        memo.add(id(o))
        it = [ describe_any(v, memo) for v in o ]
        uit = list(sorted(it))
        if len(uit) == 1:
            it = '{} {}'.format(len(o), uit[0])
        else:
            it = and_list(it)
        return 'set of {}'.format(it)
    
    def describe_array(a):
        '''Describe a numpy array in English'''
        if issubclass(a.dtype.type, np.integer):
            t = 'integer'
        elif issubclass(a.dtype.type, np.float):
            t = 'float'
        elif issubclass(a.dtype.type, np.complex):
            t = 'complex'
        elif issubclass(a.dtype.type, np.bool_):
            t = 'boolean'
        elif str(a.dtype)[:2] == '<U':
            # For a NumPy array of strings, make it an object
            t = 'object'
        else:
            t = str(a.dtype)
        s = ' x '.join(str(i) for i in a.shape)
        if s == '0':
            return 'empty array of ' + t
        return 'array of {} {}'.format(s, t)

    def describe_plot(o):
        '''describe a plot'''
        o = figureState(o)
        terms = []
        nlines = len(o['lines'])
        if nlines > 0:
            terms.append('{} line{}'.format(nlines, "s"[nlines==1:]))
        nbars = o['bars'].shape[-1]
        if nbars > 0:
            terms.append('{} bar{}'.format(nbars, "s"[nbars==1:]))
        for t in ['title', 'xlabel', 'ylabel']:
            if o[t]:
                terms.append(t)
        if len(terms) == 0:
            return 'empty plot'
        else:
            return 'plot with ' + and_list(terms)

    def describe_function(f):
        return 'function with %d parameter' % len(inspect.signature(f).parameters)
        
    def describe_any(o, memo):
        if isinstance(o, str):
            return 'string'
        # Ensure booleans come before integers because a if a problem can
        # return a bool or a np.bool_, then having int first would accept
        # True as an int, but not np.bool_
        if isinstance(o, (bool, np.bool_)):
            return 'boolean'
        if isinstance(o, (int, np.integer)):
            return 'integer'
        if isinstance(o, (float, np.floating)):
            return 'float'
        if o is None:
            return 'None'
        if isinstance(o, np.ndarray):
            return describe_array(o)
        if isinstance(o, list):
            return describe_sequence(o, 'list', memo)
        if isinstance(o, tuple):
            return describe_sequence(o, 'tuple', memo)
        if isinstance(o, dict):
            return describe_dict(o, memo)
        if isinstance(o, set):
            return describe_set(o, memo)
        if isinstance(o, matplotlib.figure.Figure):
            return describe_plot(o)
        if callable(o):
            return describe_function(o)
        return str(type(o))
    
    desc = describe_any(o, set())
    def pluralize(m):
        n = int(m.group(1))
        w = m.group(3)
        if n != 1:
            if w == 'dictionary':
                w = 'dictionaries'
            else:
                w = w + 's'
        return m.group(1) + ' ' + m.group(2) + w
    desc = re.sub(r'(\d+) (\(?)(tuple|list|dictionary|integer|float|boolean|plot|parameter)', pluralize, desc)
    return desc

import hashlib

def hash_answer(o, precision=PRECISION):
    '''return a hash to represent the answer in equality tests'''
    def str_answer(o, memo):
        '''compute a hash for an answer'''
        if not isinstance(o, (str, int, float, complex, bool)):
           if id(o) in memo:
               return '...'
           memo.add(id(o))
        if isinstance(o, np.ndarray):
            s = 'array' + np.array2string(o, precision=precision).replace('\n', '')
        elif isinstance(o, matplotlib.figure.Figure):
            s = 'figure' + str_answer(sorted(figureState(o).items()), memo)
        elif isinstance(o, float):
            s = 'float' + format(o, '.{}e'.format(precision))
        elif isinstance(o, set):
            s = str(type(o).__name__) + '(' + ','.join([str_answer(i, memo) for i in sorted(o)]) + ')'
        elif isinstance(o, (list, tuple)):
            s = str(type(o).__name__) + '(' + ','.join([str_answer(i, memo) for i in o]) + ')'
        elif isinstance(o, dict):
            s = 'dict' + str_answer(sorted(o.items()), memo)
        else:
            s = str(o)
        return s

    sa = str_answer(o, set())

    return hashlib.md5(sa.encode('utf-8')).hexdigest()

def urlretrieve(url_string, filename):
    ''' This function ignores cross domain cert exceptions '''
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    with urllib.request.urlopen(url_string, context=ctx) as u, \
            open(filename, 'wb') as f:
                f.write(u.read())

def question(notebook=None):
    ''' provide a notebook chat when comp116.chat() is placed in a notebook '''
    if not notebook:
       notebook = 'IPython.notebook.notebook_name'

    html = '''
<style>
body {font-family: Arial, Helvetica, sans-serif;}
* {box-sizing: border-box;}

/* Button used to open the chat form - fixed at the bottom of the page */
.open-button {
  background-color: #555;
  color: white;
  padding: 16px 20px;
  border: none;
  cursor: pointer;
  opacity: 0.8;
  position: fixed;
  bottom: 23px;
  right: 28px;
  width: 280px;
}

/* The popup chat - hidden by default */
.chat-popup {
  display: none;
  position: fixed;
  bottom: 0;
  right: 15px;
  border: 3px solid #f1f1f1;
  z-index: 9;
}

/* Add styles to the form container */
.form-container {
  max-width: 300px;
  padding: 10px;
  background-color: white;
}

/* Full-width textarea */
.form-container textarea {
  width: 100%;
  padding: 15px;
  margin: 5px 0 22px 0;
  border: none;
  background: #f1f1f1;
  resize: none;
  min-height: 200px;
}

/* When the textarea gets focus, do something */
.form-container textarea:focus {
  background-color: #ddd;
  outline: none;
}

/* Set a style for the submit/send button */
.form-container .btn {
  background-color: #4CAF50;
  color: white;
  padding: 16px 20px;
  border: none;
  cursor: pointer;
  width: 100%;
  margin-bottom:10px;
  opacity: 0.8;
}

/* Add a red background color to the cancel button */
.form-container .cancel {
  background-color: red;
}

/* Add some hover effects to buttons */
.form-container .btn:hover, .open-button:hover {
  opacity: 1;
}
</style>

<button class="open-button" id="questionButton116" onclick="openForm()">Questions</button>

<div class="chat-popup" id="myForm">
  <form class="form-container">
    <h1>Question or comment</h1>

    <p />
    <label for="msg">
      <b>Send a question or comment to the front of class without 
         interrupting your fellow students.
      </b>
    </label>
    <textarea placeholder="Type question or comment..." id="msg" name="msg" required></textarea>

    <button type="button", id="sendQuestionToFrontOfClassButton" class="btn">Send question to front of class</button>
    <button type="button" class="btn cancel" onclick="closeForm()">Close</button>
    <pre id="logQuestion116"></pre>
  </form>
</div>

<script>
function openForm() {
    document.getElementById("myForm").style.display = "block";
}

function closeForm() {
    document.getElementById("myForm").style.display = "none";
}
$('#sendQuestionToFrontOfClassButton').on('click', function() {
    var site = 'SITE',
        $sresp = $('#responseQuestion116');
        button = $('#questionButton116');
    //button.prop('disabled', true);
    var $log = $('#logQuestion116');
    $log.empty();
    $log.append('Submitting question to the front of class<br/>');

    // get the token by logging in
    $log.append('Logging in<br/>');
    $.ajax({
        url: site + 'io/token/token.cgi',
        dataType: 'jsonp'
    }).done(function(data) {
        var uuid = data.token,
            command = "comp116.pushQuestion('" + JSON.stringify(document.getElementById("msg").value) + "', '" + uuid + "')",
            kernel = IPython.notebook.kernel,
            handler = function (out) {
                //$('#comp116-stop-message').show();
                if (out.content.status == "ok") {
                    $log.append("Successfully submitted question<br/>");
                    $('#myForm').hide();
                    document.getElementById("msg").value = "";
                    button.prop('disabled', false);
                } else if(out.content.status == "error") {
                    $log.append(out.content.ename + ": " + out.content.evalue);
                    button.prop('disabled', false);
                } else { // if output is something we haven't thought of
                    $log.append("[out type not implemented]<br/>")
                    button.prop('disabled', false);
                }
            };
        $log.append('Submitting<br/>');

        // I don't know if handle_python_output is working 12/11/18
        function handle_python_output(out_type, out){
           $log.append("inside handle_python_output");
           console.log("inside handle_python_output");
           console.log(out_type);
           console.log(out);
           var res = null;
            // if output is a print statement
           if(out_type == "stream"){
               res = out.data;
           }
           // if output is a python object
           else if(out_type === "pyout"){
               res = out.data["text/plain"];
           }
           // if output is a python error
           else if(out_type == "pyerr"){
               res = out.ename + ": " + out.evalue;
           }
           // if output is something we haven't thought of
           else{
               res = "[out type not implemented]";   
           }
           document.getElementById("result_output").value = res;
        }
        kernel.execute(command, {shell: { reply: handler }, "output": handle_python_output});
    }).fail(function() {
        $sresp.html("Login failed. If you didn't get a login prompt, ensure you are online by opening a browser tab to python.org");
        if (! navigator.onLine) {
           $sresp.html('Browser offline');
        }
        button.prop('disabled', true);
    });
});
</script>
'''.replace('SITE', Site)
    return ipd.display(ipd.HTML(html))

def attendance():
    ''' provide a floating box for attendance code displayed by COMP116 staff '''

    html = '''
<style>

.submit-code {
  background-color: #4B9CD3;
  color: white;
  border: none;
  cursor: pointer;
  opacity: 0.6;
  position: fixed;
  bottom: 5px;
  right: 5px;
  width: 200px;
}

</style>

<iframe class="submit-code" src="SITE/io/submitCode/submitCode.cgi?noheader=True" 
        width="25" height="100" style="float:raight" />

'''.replace('SITE', Site)
    return ipd.HTML(html)


def array_to_html(arr, row_names=None, col_names=None, title=None):
    ''' array_to_html, if placed at the end of a Anaconda cell, will
        display the array in html.   It uses pandas.
    '''
    if len(arr.shape) not in [1, 2]:
       print('The array must be a one- or two-dimensional array. This array is',
             len(arr.shape), 'dimensions')
       return

    if title:
        ipd.display(ipd.HTML('<h1>' + title + '</h1>'))
    df = pd.DataFrame(arr, index=row_names, columns=col_names)
    return ipd.display(ipd.HTML(df.to_html()))
