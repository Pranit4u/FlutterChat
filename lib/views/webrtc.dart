import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';

class VideoRenderer extends StatefulWidget {
  final bool caller;
  final String chatRoomId;

  const VideoRenderer({Key key, this.caller, this.chatRoomId})
      : super(key: key);

  @override
  _VideoRendererState createState() => _VideoRendererState();
}

class _VideoRendererState extends State<VideoRenderer> {
  Stream<QuerySnapshot> stream;
  bool answered = false;
  bool candidated = false;
  bool offered = false;
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  MediaStream _localStream;
  RTCPeerConnection _peerConnection;

  @override
  void dispose() {
    super.dispose();
    disposeRenderer();
  }

  disposeRenderer() async {
    await _localRenderer.dispose();
    await _remoteRenderer.dispose();
    await _peerConnection.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.lightGreen,
      child: Column(
        children: [
        Expanded(
        child: Row(
          children: [
            Flexible(child: Container(
              key: Key('local'),
              margin: EdgeInsets.fromLTRB(5, 5, 5, 5),
              decoration: BoxDecoration(color: Colors.black),
              child: RTCVideoView(_localRenderer),
            )),
          ],
        ),
      ),
          Expanded(
            child: Row(
              children: [
                Flexible(child: Container(
                  key: Key('remote'),
                  margin: EdgeInsets.fromLTRB(5, 5, 5, 5),
                  decoration: BoxDecoration(color: Colors.black),
                  child: RTCVideoView(_remoteRenderer),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  initRenderer() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  void initState() {
    super.initState();
    initRenderer();
    _getUserMedia();
    _createPeerConnection().then((pc) {
      _peerConnection = pc;
      setState(() {

      });
      getStream().then((val){
        stream = val;
        doStuff();
      });
    });
  }

  _getUserMedia() async {
    Map<String, dynamic> mediaConstraints = {
      'audio': false,
      'video': {'facing mode': 'user'}
    };
    _localStream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localRenderer.srcObject = _localStream;

  }

  _createPeerConnection() async {
    Map<String, dynamic> config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    };
    final Map<String, dynamic> offerSDPConstraints = {
      'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true},
      'optional': []
    };
    RTCPeerConnection pc =
        await createPeerConnection(config, offerSDPConstraints);
    pc.addStream(_localStream);
    pc.onIceCandidate = (e) async {
      if (e.candidate != null) {
        String candidate = json.encode({
          'candidate': e.candidate.toString(),
          'sdpMid': e.sdpMid.toString(),
          'sdpMlineIndex': e.sdpMlineIndex
        });
        uploadCandidate(candidate);
      }
    };
    pc.onConnectionState = (e) {
      // print(e);
    };
    pc.onAddStream = (stream) {
      // print('added stream: ' + stream.id);
      // _remoteRenderer.srcObject = stream;
    };
    return pc;
  }

  void _setCandidate(String jsonString) async {
    dynamic session = await jsonDecode(jsonString);
    print(session['candidate']);
    dynamic candidate = new RTCIceCandidate(
        session['candidate'], session['sdpMid'], session['sdpMlineIndex']);
    await _peerConnection.addCandidate(candidate);
  }

  void createOffer() async {
    RTCSessionDescription description =
        await _peerConnection.createOffer({'offerToReceiveVideo': 1});
    var session = parse(description.sdp);
    String jsonSession = json.encode(session);
    uploadOffer(jsonSession);
    _peerConnection.setLocalDescription(description);
  }

  void _createAnswer() async {
    RTCSessionDescription description =
        await _peerConnection.createAnswer({'offerToReceiveVideo': 1});
    var session = parse(description.sdp);
    String jsonSession = json.encode(session);
    uploadAnswer(jsonSession);
    _peerConnection.setLocalDescription(description);
  }

  void setRemoteDescription(String jsonString) async {
    dynamic session = await jsonDecode(jsonString);
    String sdp = write(session, null);
    RTCSessionDescription description =
        new RTCSessionDescription(sdp, widget.caller ? 'answer' : 'offer');
    print(description.toMap());
    await _peerConnection.setRemoteDescription(description);
  }

  void uploadCandidate(String candidate) async{
    if (!candidated && !widget.caller) {
       await FirebaseFirestore.instance
          .collection("ChatRoom")
          .doc(widget.chatRoomId)
          .collection("webrtc")
          .doc("candidate")
          .set({"candidate": candidate}).catchError((e) {
        print(e.toString());
      });
      candidated = true;
      print(candidate);
    }
  }

  void doStuff() async {
    if (widget.caller) {
      StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) print("hello...");
          for (int i = 0; i < snapshot.data.docs.length; i++) {
            switch (snapshot.data.docs[i]["name"]) {
              case "random":
                print("\n\nrandom\n\n");
                break;
              case "answer":
                if (!answered && snapshot.data.docs[i]["jsonSession"] != "") {
                  setRemoteDescription(snapshot.data.docs[i]["jsonSession"]);
                  answered = true;
                  return Container(
                    height: 0,
                  );
                }
                break;
              case "offer":
                if (!offered && snapshot.data.docs[i]["jsonSession"] == "") {
                  createOffer();
                  offered = true;
                  return Container(
                    height: 0,
                  );
                }
                break;
              case "candidate":
                if (offered &&
                    answered &&
                    !candidated &&
                    snapshot.data.docs[i]["candidate"] != "") {
                  _setCandidate(snapshot.data.docs[i]["candidate"]);
                  candidated = true;
                  return Container(
                    height: 0,
                  );
                }
                break;
              case "connect":
                if (snapshot.data.docs[i]["connected"] == false) {
                  disposeRenderer();
                  return Container(
                    height: 0,
                  );
                }
                break;
              default:
                break;
            }
          }
          return Container(
            height: 0,
          );
        },
      );
    } else {
      StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData){
            print("\n\ndoesnt have data\n\n");
            return Container(height: 0,);
          }
          for (int i = 0; i < snapshot.data.docs.length; i++) {
            switch (snapshot.data.docs[i]["name"]) {
              case "offer":
                if (!offered && snapshot.data.docs[i]["jsonSession"] != "") {
                  setRemoteDescription(snapshot.data.docs[i]["jsonSession"]);
                  offered = true;
                  return Container(
                    height: 0,
                  );
                }
                break;
              case "answer":
                if (!answered && snapshot.data.docs[i]["jsonSession"] == "") {
                  _createAnswer();
                  answered = true;
                  return Container(
                    height: 0,
                  );
                }
                break;
              case "connect":
                if (snapshot.data.docs[i]["connected"] == false) {
                  disposeRenderer();
                  return Container(
                    height: 0,
                  );
                }
                break;
              default:
                break;
            }
          }
          return Container(
            height: 0,
          );
        },
      ) ;
    }
  }

  void uploadAnswer(String jsonSession) async{
    await FirebaseFirestore.instance
        .collection("ChatRoom")
        .doc(widget.chatRoomId)
        .collection("webrtc")
        .doc("answer")
        .set({"jsonSession": jsonSession}).catchError((e) {
      print(e.toString());
    });
    answered = true;
    print(jsonSession);
  }

  void uploadOffer(String jsonSession) async{
    await FirebaseFirestore.instance
        .collection("ChatRoom")
        .doc(widget.chatRoomId)
        .collection("webrtc")
        .doc("offer")
        .set({"jsonSession": jsonSession}).catchError((e) {
      print(e.toString());
    });
    offered = true;
    print(jsonSession);
  }

  getStream() async{
    return await FirebaseFirestore.instance
        .collection('ChatRoom')
        .doc(widget.chatRoomId)
        .collection("webrtc")
        .snapshots();
  }
}
