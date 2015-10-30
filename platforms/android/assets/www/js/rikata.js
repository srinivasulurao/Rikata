/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 * JAI NIRMAL BABA
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
//deviceready
//pause
//resume
//backbutton
//menubutton
//searchbutton
//startcallbutton
//endcallbutton
//volumedownbutton
//volumeupbutton

var ajaxLoader="<img src='img/ajax-loader.gif'>";
//###############################################################################################
//Initialize the Application.                                                                   #
//###############################################################################################
var app = {
    // Application Constructor
    initialize: function() {
        this.bindEvents();
    },
    // Bind Event Listeners
    //
    // Bind any events that are required on startup. Common events are:
    // 'load', 'deviceready', 'offline', and 'online'.
    bindEvents: function() {
        document.addEventListener('deviceready', this.onDeviceReady, false);
    },
    // deviceready Event Handler
    //
    // The scope of 'this' is the event. In order to call the 'receivedEvent'
    // function, we must explicitly call 'app.receivedEvent(...);'
    onDeviceReady: function() {
        app.receivedEvent('deviceready');
        document.getElementsByClassName('recieved')[0].style.display="none";
    },
    // Update DOM on a Received Event
    receivedEvent: function(id) {
        var parentElement = document.getElementById(id);
        var listeningElement = parentElement.querySelector('.listening');
        var receivedElement = parentElement.querySelector('.received');

        listeningElement.setAttribute('style', 'display:none;');
        receivedElement.setAttribute('style', 'display:block');


        console.log('Received Event: ' + id);
    }
};

function BackVar(){

    document.getElementById('videoArea').innerHTML=ajaxLoader;
    setTimeout(function () {
    window.location='index.html';
    },3000);
}

//###############################################################################################
//Capture Video & Show.                                                                         #
//###############################################################################################
function captureVideo(){
navigator.device.capture.captureVideo(videoCaptureSuccess,videoCaptureFailed);
    //console.log("Its Working");
}

var videoCaptureSuccess=function videoCaptureSuccess(s){
    var v = "<video controls='controls'>";
    v += "<source src='" + s[0].fullPath + "' type='video/mp4'>";
    v += "</video>";
    document.querySelector("#videoArea").innerHTML = v;
};

document.addEventListener("backbutton", BackVar, false);


var videoCaptureFailed=function videoCaptureFailed(e){
    console.log("Capture Error :","Something is wrong with the plugin!");
};

//###############################################################################################
//Select Video & Show.                                                                          #
//###############################################################################################

document.addEventListener("deviceready", makeFileSystemReady, true);
var globalFileSystem;
function makeFileSystemReady(){
 window.requestFileSystem(LocalFileSystem.PERSISTENT, 0, onFileSystemSuccess, onFileSystemError);
}


function onFileSystemSuccess(fs){
    globalFileSystem=fs; //Initialized the global file system.
}


function onFileSystemError(){
    console.log("Unable to fetch the data from your phone !");
}

function chooseFromGallery(){

var dirReader = globalFileSystem.root.createReader();
dirReader.readEntries(galleryFiles,galleryFilesErrors);
}

function galleryFiles(entries){
        var s = "<p style='color:white'>";
        console.dir(entries);
        for(var i=0,len=entries.length; i<len; i++) {
        //entry objects include: isFile, isDirectory, name, fullPath
        s+= entries[i].fullPath;
            
            if (entries[i].isFile) {
            s += " [F]";
            }
            if(entries[i].isDirectory) {
                innerDir=entries[i].filesystem.root.createReader();
                innerDir.readEntries(galleryFiles,galleryFilesErrors);
            s += " [D]";
            }
        s += "<br/>";

        }
        s+="<p/>";
    
    document.getElementById('videoArea').innerHTML=s;
}

function galleryFilesErrors(){
    alert("Unable to use the file system !");
}




//###############################################################################################



