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

duration=2; // Lets make the duration 2 secs as of now.

function captureVideo(){
navigator.device.capture.captureVideo(videoCaptureSuccess,videoCaptureFailed);
    //console.log("Its Working");
}

var videoCaptureSuccess=function videoCaptureSuccess(s){
    console.dir(s);
    var v = "<video controls='controls' id='videoAction'>";
    v += "<source src='" + s[0].fullPath + "' type='video/mp4'>";
    v += "</video>";
    
    document.querySelector("#videoArea").innerHTML = v;
    document.getElementById('videoSource').value=s[0].fullPath;
    document.getElementById('videoLength').value=duration;
    invokeRangeSlider();
    invokeQualitySelect();
    enableTrim();
};

document.addEventListener("backbutton", BackVar, false);


var videoCaptureFailed=function videoCaptureFailed(e){
    
    document.querySelector("#videoArea").innerHTML ="";
    document.getElementById('videoSource').value="";
    document.getElementById('videoLength').value="";
    removeQualitySelect();
    removeRangeSlider();
    disableTrim();
    alert("Process Terminated !");
    
};

//###############################################################################################
//Select Video & Show.                                                                          #
//###############################################################################################

function chooseFromGallery(){
    navigator.camera.getPicture(videoTakenFromGallerySuccess,videoTakenFromGalleryFailed,{ sourceType: navigator.camera.PictureSourceType.PHOTOLIBRARY,
               mediaType:navigator.camera.MediaType.VIDEO,allowEdit:true,
                                         });
}

function videoTakenFromGallerySuccess(res){
    var v = "<video controls='controls' id='videoAction'>";
    v += "<source src='" + res + "' type='video/mp4'>";
    v += "</video>";
    choosenVideo=document.getElementById('videoAction');
   
    document.querySelector("#videoArea").innerHTML = v;
    document.getElementById('videoSource').value=res;
    document.getElementById('videoLength').value=duration;
    invokeRangeSlider();
    invokeQualitySelect();
    enableTrim();
    
}

function mediaSuccess(){
}

function mediaError(){
    
}

function videoTakenFromGalleryFailed(res){
    document.querySelector("#videoArea").innerHTML ="";
    document.getElementById('videoSource').value="";
    document.getElementById('videoLength').value="";
    removeQualitySelect();
    removeRangeSlider();
    disableTrim();
    alert("Process Terminated !");
}


//###############################################################################################
//Start Cutting the Video.                                                                      #
//###############################################################################################

function invokeRangeSlider(){
    var minRange=0;
    var maxRange=document.getElementById('videoLength').value;
    $('#rangeSliderG').show();
}

function removeRangeSlider(){
    $('#rangeSliderG').hide();
}

function invokeQualitySelect(){
    var qualitySelect="<select class='form-control' style='margin-top:10px;width:95%;display:block;margin:auto'>";
    qualitySelect+="<option value=''>--SELECT QUALITY--</option><option value='50'>Low</option><option value='75'>Medium</option><option value='100'>High</option>";
    qualitySelect+="</select>";
    document.getElementById('selectQuality').innerHTML=qualitySelect;
}

function removeQualitySelect(){
    document.getElementById('selectQuality').innerHTML='';
}

function disableTrim(){
    $('#trimVideo').hide();
}

function enableTrim(){
    $('#trimVideo').show();
}

function trimVideo(){
    cordova.plugins.barcodeScanner.scan(
      function (result) {
          alert("We got a barcode\n" +
                "Result: " + result.text + "\n" +
                "Format: " + result.format + "\n" +
                "Cancelled: " + result.cancelled);
      }, 
      function (error) {
          alert("Scanning failed: " + error);
      }
   );
}

function trimVideoOLd(){
    
    var rikata_date=new Date();
    var videoFilePath=$('#videoSource').val();
    var videoFileName="Video-"+rikata_date.getFullYear()+"-"+rikata_date.getMonth()+"-"+rikata_date.getDate()+"-"+rikata_date.getHours()+"-"+rikata_date.getMinutes()+"-"+rikata_date.getSeconds();
    console.log(videoFileName);
    
    VideoEditor.transcodeVideo(
        videoTranscodeSuccess,
        videoTranscodeError,
        {
            fileUri: videoFilePath, 
            outputFileName: videoFileName
        }
    );
    
}

function videoTranscodeSuccess(result){
    alert("Video Trimming Saved Successfully");
}
  
function videoTranscodeError(err){
    console.log(err);
     alert("Unable to process your request!");
}
