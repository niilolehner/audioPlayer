import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AUDIO PLAYER',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'AUDIO PLAYER'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  List<String> audioFiles = [];
  int currentTrackIndex = 0;
  double currentPosition = 0.0;
  double totalDuration = 0.0;

  @override
  void initState() {
    super.initState();
    audioPlayer.onAudioPositionChanged.listen((Duration position) {
      setState(() {
        currentPosition = position.inMilliseconds.toDouble();
      });
    });
    audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        totalDuration = duration.inMilliseconds.toDouble();
      });
    });
  }

  void _play() async {
    int result = await audioPlayer.play(audioFiles[currentTrackIndex]);
    if (result == 1) {
      setState(() {
        isPlaying = true;
      });
    }
  }

  void _pause() async {
    int result = await audioPlayer.pause();
    if (result == 1) {
      setState(() {
        isPlaying = false;
      });
    }
  }

  void _nextTrack() {
    if (currentTrackIndex < audioFiles.length - 1) {
      setState(() {
        currentTrackIndex++;
      });
      _play();
    }
  }

  void _previousTrack() {
    if (currentTrackIndex > 0) {
      setState(() {
        currentTrackIndex--;
      });
      _play();
    }
  }

  void _seek(double position) async {
    int result = await audioPlayer.seek(Duration(milliseconds: position.toInt()));
    if (result == 1) {
      setState(() {
        currentPosition = position;
      });
    }
  }

  void _addAudioFile(File file) async {
    setState(() {
      audioFiles.add(file.path);
    });
  }

  void _removeAudioFile(int index) async{
    setState(() {audioFiles.removeAt(index);});
    if(currentTrackIndex >= audioFiles.length){
      currentTrackIndex = audioFiles.length -1;
    }
  }

  Future<void> _showAddAudioDialog(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      _addAudioFile(file);
    }
  }

  Future<void> _showRemoveAudioDialog(BuildContext context, int index) async{
    return showDialog<void>(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: Text('Remove Audio File'),
          content: Text('Remove this audio file?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Remove'),
              onPressed: (){
                _removeAudioFile(index);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String getFileName(String url){
    return url.split('/').last;
  }

  String formatDuration(Duration duration){
    String twoDigits(int n){
      if(n>=10)return "$n";
      return "0$n";
    }
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions:[
          IconButton(
            iconSize :48,
            icon : Icon(Icons.add),
            onPressed : () =>_showAddAudioDialog(context),
          ),
        ],
      ),
      body : Center(
        child : Column(
          mainAxisAlignment : MainAxisAlignment.center,
          children : <Widget>[
            Expanded(
              child : ListView.builder(
                itemCount : audioFiles.length,
                itemBuilder : (context, index){
                  return ListTile(
                    title : Text(getFileName(audioFiles[index])),
                    onTap : (){
                      setState((){
                        currentTrackIndex = index;
                      });
                      _play();
                    },
                    trailing : IconButton(
                      icon : Icon(Icons.delete),
                      onPressed : () =>_showRemoveAudioDialog(context,index),
                    ),
                    tileColor:
                    index == currentTrackIndex ? Colors.blue[50] : null,
                  );
                },
              ),
            ),
            Padding(
              padding : const EdgeInsets.symmetric(horizontal :16.0),
              child : Row(
                mainAxisAlignment : MainAxisAlignment.spaceBetween,
                children:[
                  Text(formatDuration(Duration(milliseconds : currentPosition.toInt())), style : TextStyle(fontSize :20)),
                  Text(formatDuration(Duration(milliseconds :(totalDuration - currentPosition).toInt())), style : TextStyle(fontSize :20)),
                ],
              ),
            ),
            Slider(
              value : currentPosition,
              min :0.0,
              max : totalDuration,
              onChanged :(double value)=>_seek(value),
            ),
            Row(
              mainAxisAlignment : MainAxisAlignment.center,
              children:[
                IconButton(
                  iconSize :48,
                  icon : Icon(Icons.skip_previous),
                  onPressed :
                  currentTrackIndex >0 ?_previousTrack:null,
                ),
                SizedBox(width :20),
                IconButton(
                  iconSize :48,
                  icon :
                  isPlaying ? Icon(Icons.pause):Icon(Icons.play_arrow),
                  onPressed :
                  isPlaying ?_pause:_play,
                ),
                SizedBox(width :20),
                IconButton(
                  iconSize :48,
                  icon : Icon(Icons.skip_next),
                  onPressed :
                  currentTrackIndex <audioFiles.length -1 ?_nextTrack:null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
