import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video_call/component/custom_elevated_button.dart';
import 'package:flutter_video_call/const/agora.dart';
import 'package:permission_handler/permission_handler.dart';

class CamScreen extends StatefulWidget {
  const CamScreen({super.key});

  @override
  State<CamScreen> createState() => _CamScreenState();
}

class _CamScreenState extends State<CamScreen> {
  RtcEngine? engine; // 아고라 엔진을 저장할 변수
  int? uid; // 내 ID
  int? otherUid; // 상대방 ID

  // 화상 통화에 필요한 권한인 카메라 권한과 마이크 권한을 받는 비동기 함수
  Future<bool> init() async{
    final resp = await [Permission.camera, Permission.microphone].request();

    final cameraPermission = resp[Permission.camera];
    final micPermission = resp[Permission.microphone];

    if(cameraPermission != PermissionStatus.granted ||
       micPermission != PermissionStatus.granted){
      throw '카메라 또는 마이크 권한이 없습니다.';
    }

    if(engine == null){
      // 엔진이 정의되지 않았으면 새로 정의하기
      engine = createAgoraRtcEngine();

      // 아고라 엔진을 초기화하기
      await engine!.initialize(
        // 초기화할 때 사용할 설정을 제공
        RtcEngineContext(
          appId: APP_ID,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting
        ),
      );

      // RtcEngine에 이벤트 콜백 함수들을 등록하는 함수를 실행
      engine!.registerEventHandler(
        // 아고라 엔진에서 받을 수 있는 이벤트 값들 등록
        RtcEngineEventHandler(
          // 채널 접속에 성공했을 때 실행
          onJoinChannelSuccess: (RtcConnection connection, int elapsed){
            // connection : 영상 통화 정보에 관련된 값
            // elapsed : joinChannel을 실행한 후 콜백이 실행되기까지 걸린 시간
            print('채널에 입장했습니다. uid : ${connection.localUid}');
            setState(() {
              uid = connection.localUid;
            });
          },

          // 채널 퇴장했을 때 실행
          onLeaveChannel: (RtcConnection connection, RtcStats stats){
            print('채널 퇴장');
            setState(() {
              uid = null;
            });
          },

          // 다른 사용자가 접속했을 때 실행
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed){
            // connection : 영상 통화 정보에 관련된 값
            // remoteUid : 상대방 고유 ID
            // elapsed : 내가 채널을 들어왔을 때부터 상대가 들어올 때까지 걸린 시간
            print('상대가 채널에 입장했습니다. uid : $remoteUid');
            setState(() {
              otherUid = remoteUid;
            });
          },

          // 다른 사용자가 채널을 나갔을 때 실행
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason){
            // reason : 방에서 나가게 된 이유(직접 나가기 or 네트워크 끊김 등)
            print('상대가 채널에서 나갔습니다. uid : $uid}');
            setState(() {
              otherUid = null;
            });
          },
        ),
      );

      // 엔진으로 영상을 송출하겠다고 설정
      await engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      // 동영상 기능을 활성화
      await engine!.enableVideo();
      // 카메라를 이용해 동영상을 화면에 실행
      await engine!.startPreview();
      // 채널에 들어가기
      await engine!.joinChannel(token: TEMP_TOKEN, channelId: CHANNEL_NAME, uid: 0, options: ChannelMediaOptions());
      // options : 영상 송출과 관련된 여러 옵션을 상세하게 지정할 수 있음, 현재는 기본 설정을 사용
      // uid : 내 고유 ID를 지정할 수 있음, 현재는 입력이 0이므로 자동으로 고유 ID가 배정됨
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[500],
        iconTheme: IconThemeData(
          color: Colors.white, // 뒤로가기 아이콘 색상 설정
        ),
        title: Text(
          '영상통화 간단히 만들어버리기',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.0,
          ),
        ),
      ),
      body: FutureBuilder(  // Future를 반환하는 함수의 결과에 따라 위젯을 렌더링할 때 사용된다.
        future: init(),     // future 네임드 파라미터에 Future값을 반환하는 함수를 넣어주고,
        builder: (BuildContext context, AsyncSnapshot snapshot){
          // builder 네임드 파라미터에 Future 값에 따라 다르게 렌더링해주고 싶은 로직을 작성하면 된다.
          // AsyncSnapshot은 future 매개변수에 입력한 함수의 결과값 및 에러를 제공해주는 역할을 한다.
          // AsyncSnapshot에서 제공하는 값이 변경될 때마다 builder() 함수가 재실행된다. 즉, future의 init() 함수의 결과값 및 에러가 변경될 때마다 재실행된다.
          if(snapshot.hasError){
            return Center(
              child: Text(
                snapshot.error.toString(),
              ),
            );
          }

          // AsyncSnapshot<T> 클래스는 불변 객체이다.
          // build() 함수가 재실행되면서, FutureBuilder() 함수가 재실행되고, future 매개변수의 init() 함수가 재실행되는데,
          // 비동기 함수인 init() 함수가 재실행되면서 필연적으로, ConnectionState.waiting으로 변했다가 ConnectionState.done으로 변하게 된다.
          // 로딩중일때의 조건에 snapshot.ConnectionState == ConnectionState.waiting을 사용할 수 있지만,
          // 불변 객체인 AsyncSnapshot의 snapshot.hasData가 true로 캐싱이 되어있기 때문에 로딩중일때의 조건에 !snapshot.hasData를 이용해야,
          // 사용자에게 로딩중인 UI가 효용없이 잠깐 뜨는 것을 방지할 수 있다.
          if(!snapshot.hasData){
            return Center(
              child: CircularProgressIndicator(color: Colors.blue[500]),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    renderMainView(),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        color: Colors.grey,
                        height: 160,
                        width: 120,
                        child: renderSubView(),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: CustomElevatedButton(
                  onPressed: () async{
                    if(engine != null){
                      await engine!.leaveChannel();
                    }
                    Navigator.of(context).pop();
                  },
                  text: '채널 나가기'
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 내 핸드폰이 찍는 화면 렌더링하는 위젯
  Widget renderSubView(){
    if(uid != null){
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: engine!,
          canvas: VideoCanvas(uid: 0), // 0을 입력해서 내 영상을 보여준다.
        ),
      );
    }
    else{ // 내가 채널에 접속하지 않은 상태
      return Center(
          child: CircularProgressIndicator(color: Colors.blue[500])
      );
    }
  }

  // 상대 핸드폰이 찍는 화면 렌더링하는 위젯
  Widget renderMainView(){
    if(otherUid != null){
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: engine!,
          canvas: VideoCanvas(uid: otherUid), // 상대방 ID를 입력해서 상대방 영상을 보여준다.
          connection: RtcConnection(channelId: CHANNEL_NAME),
        ),
      );
    }
    else{ // 상대가 채널에 접속하지 않은 상태
      return Center(
        child: Text(
          '다른 사용자가 입장할 때까지 대기해주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16.0,
          ),
        ),
      );
    }
  }
}
