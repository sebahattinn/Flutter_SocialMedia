import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRtcShareService {
  RTCPeerConnection? _pc;
  RTCDataChannel? _dc;

  // Optional callbacks (wire these from UI)
  void Function(Map<String, dynamic> ice)? onIceCandidate;
  void Function(Uint8List bytes)? onBytes;
  void Function(String text)? onText;

  Future<void> init({bool createDataChannel = true}) async {
    _pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    });

    // If the remote side creates the channel first:
    _pc!.onDataChannel = (RTCDataChannel dc) {
      _dc = dc;
      _attachChannelHandlers();
    };

    // Send ICE candidates to your signaling channel:
    _pc!.onIceCandidate = (RTCIceCandidate c) {
      if (c.candidate == null) return;
      onIceCandidate?.call({
        'candidate': c.candidate,
        'sdpMid': c.sdpMid,
        'sdpMLineIndex':
            c.sdpMLineIndex, // note: constructor uses sdpMlineIndex
      });
    };

    if (createDataChannel) {
      _dc = await _pc!.createDataChannel(
        'media',
        RTCDataChannelInit()..ordered = true,
      );
      _attachChannelHandlers();
    }
  }

  void _attachChannelHandlers() {
    _dc?.onMessage = (RTCDataChannelMessage msg) {
      if (msg.isBinary) {
        final data = msg.binary; // Uint8List?
        onBytes?.call(data);
      } else {
        onText?.call(msg.text);
      }
    };
  }

  // OFFERER side: create offer, send JSON {sdp,type} to remote
  Future<String> createOfferSdp() async {
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    return jsonEncode({'sdp': offer.sdp, 'type': offer.type});
  }

  // ANSWERER side: receive offer JSON, set remote, create answer, return answer JSON
  Future<String> createAnswerFromRemoteOffer(String offerJson) async {
    final m = jsonDecode(offerJson) as Map<String, dynamic>;
    final offer = RTCSessionDescription(
      m['sdp'] as String,
      m['type'] as String,
    );
    await _pc!.setRemoteDescription(offer);

    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    return jsonEncode({'sdp': answer.sdp, 'type': answer.type});
  }

  // OFFERER side: set the answer received from remote
  Future<void> setRemoteAnswer(String answerJson) async {
    final m = jsonDecode(answerJson) as Map<String, dynamic>;
    final answer = RTCSessionDescription(
      m['sdp'] as String,
      m['type'] as String,
    );
    await _pc!.setRemoteDescription(answer);
  }

  // Add ICE from remote (handle both key variants)
  Future<void> addIceCandidate(Map<String, dynamic> cand) async {
    final idx = (cand['sdpMLineIndex'] ?? cand['sdpMlineIndex']) as int?;
    final ice = RTCIceCandidate(
      cand['candidate'] as String?,
      cand['sdpMid'] as String?,
      idx,
    );
    await _pc!.addCandidate(ice);
  }

  // Send arbitrary bytes (convert List<int> -> Uint8List)
  void sendBytes(List<int> bytes) {
    _dc?.send(RTCDataChannelMessage.fromBinary(Uint8List.fromList(bytes)));
  }

  void sendText(String text) {
    _dc?.send(RTCDataChannelMessage(text));
  }

  void dispose() {
    _dc?.close();
    _pc?.close();
  }
}
