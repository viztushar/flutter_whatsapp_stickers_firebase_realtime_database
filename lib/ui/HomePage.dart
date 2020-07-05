import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whatsappstickerapi/whatsappstickerapi.dart';
import '../models/stickerPacks.dart';
import '../models/stickers.dart';
import '../models/model.dart';
import 'dart:async';
import 'dart:convert';
import 'StickerDetails.dart';
import 'package:dio/dio.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StickerPacks stickerPack = StickerPacks();
  List<StickerPacks> st = List<StickerPacks>();
  bool isLoading, isDownloading = true;
  int iD = -1;
  List<String> downloadList = List<String>();
  List<String> stickerImageList = List<String>();
  @override
  void initState() {
    super.initState();
    isLoading = true;
    isDownloading = true;
    iD = -1;
    this.getJsonData();
  }

  Future getJsonData() async {
    //config the firebase using json file
    var database = FirebaseDatabase.instance.reference();
    //store links
    var android_play_store_link = database.child("android_play_store_link");
    var ios_app_store_link = database.child("ios_app_store_link");
    //downloading sticker packs into model class
    database.child("sticker_packs").once().then((value) {
      List<dynamic> resultList = value.value;
      for (int i = 0; i < resultList.length; i++) {
        List<Stickers> s = List<Stickers>();
        List<dynamic> stickers = resultList[i]["stickers"];
        for (int j = 0; j < stickers.length; j++) {
          s.add(Stickers(
              imagefile: stickers[j]['image_file'],
              emojis: stickers[j]['emojis']));
        }
        st.add(StickerPacks(
            identifier: resultList[i]['identifier'],
            name: resultList[i]['name'],
            publisher: resultList[i]['publisher'],
            trayimagefile: resultList[i]['tray_image_file'],
            publisheremail: resultList[i]['publisher_email'],
            publisherwebsite: resultList[i]['publisher_website'],
            privacypolicywebsite: resultList[i]['privacy_policy_website'],
            licenseagreementwebsite: resultList[i]['license_agreement_website'],
            stickers: s));
      }
      setState(() {
        isLoading = false;
      });
    });
  }

  navigateToDetailsScreen(id, context) {
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
      return MyStickerDetails(
        stickerPacks: st[id],
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sticker Name"),
      ),
      body: Container(
        child: Center(
          child: isLoading
              ? CircularProgressIndicator()
              : ListView.builder(
                  itemCount: st.length,
                  itemBuilder: (context, i) {
                    return Card(
                      child: Container(
                        padding: EdgeInsets.all(10.0),
                        child: Row(
                          children: <Widget>[
                            GestureDetector(
                              onTap: () {
                                navigateToDetailsScreen(i, context);
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Text(
                                        st[i].name,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        ' • ',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      Text(
                                        st[i].publisher,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Wrap(
                                    alignment: WrapAlignment.start,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    direction: Axis.horizontal,
                                    spacing: 8.0,
                                    runSpacing: 4.0,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Image.network(
                                            st[i].sticker[0].imagefile,
                                            height: 70.0,
                                            width: 70.0,
                                          ),
                                          Image.network(
                                            st[i].sticker[1].imageFile,
                                            height: 70.0,
                                            width: 70.0,
                                          ),
                                          Image.network(
                                            st[i].sticker[2].imageFile,
                                            height: 70.0,
                                            width: 70.0,
                                          ),
                                          st[i].sticker.length > 3
                                              ? Image.network(
                                                  st[i].sticker[3].imageFile,
                                                  height: 70.0,
                                                  width: 70.0,
                                                )
                                              : SizedBox(
                                                  width: 70.0,
                                                  height: 70.0,
                                                ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Flex(
                                  direction: Axis.horizontal,
                                  children: <Widget>[
                                    if (!downloadList
                                        .contains(st[i].identiFier)) ...[
                                      iD == i && !isDownloading
                                          ? CircularProgressIndicator()
                                          : IconButton(
                                              icon: Icon(Icons.add),
                                              onPressed: () {
                                                setState(() {
                                                  iD = i;
                                                  isDownloading = false;
                                                  print(isLoading);
                                                  downloadSticker(st[i]);
                                                });
                                              },
                                            ),
                                    ],
                                    if (downloadList
                                        .contains(st[i].identiFier)) ...[
                                      IconButton(
                                        icon: Icon(
                                          Icons.add,
                                          color: Colors.greenAccent,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            iD = i;
                                            print(i);
                                            addToWhatsapp(st[i]);
                                          });
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> addToWhatsapp(StickerPacks s) async {
    try {
      WhatsappstickerApi.addStickerPackToWhatsApp(
          identifier: s.identiFier, name: s.name);
    } on PlatformException catch (e) {
      print(e.details);
    }
  }

  Future<void> downloadSticker(StickerPacks s) async {
    if (s.publisherEmail == null) s.publisherEmail = "0";
    print((s.publisherEmail == null).toString() +
        s.identiFier +
        " " +
        s.name +
        " " +
        s.publisher +
        " " +
        s.trayImageFile +
        " " +
        s.publisherEmail +
        " " +
        s.publisherWebsite +
        " " +
        s.privacyPolicyWebsite +
        " " +
        s.licenseAgreementWebsite.contains("").toString() +
        " ");
    stickerImageList.clear();
    if (!downloadList.contains(s.identiFier)) {
      await Permission.storage.request();
      Dio dio = Dio();
      var dirToSave = await getApplicationDocumentsDirectory();
      var path = await Directory(dirToSave.path +
              "/" +
              "stickers_asset" +
              "/" +
              s.identiFier +
              "/")
          .create(recursive: true);
      var trypath = await Directory(dirToSave.path +
              "/" +
              "stickers_asset" +
              "/" +
              s.identiFier +
              "/try/")
          .create(recursive: true);
      print(path.path + "\n" + trypath.path);
      String tryFilePath = trypath.path + basename(s.trayImageFile);
      print(tryFilePath);
      await dio.download(s.trayImageFile, tryFilePath,
          onReceiveProgress: (rec, total) {
        print((rec / total) * 100);
        print("try image downloaded");
      });
      for (int i = 0; i < s.sticker.length; i++) {
        String imageFilePath = path.path + basename(s.sticker[i].imageFile);
        stickerImageList.add(basename(s.sticker[i].imageFile));
        await dio.download(s.sticker[i].imageFile, imageFilePath,
            onReceiveProgress: (rec, total) {
          print((rec / total) * 100);
        });
      }
      try {
        WhatsappstickerApi.addToJson(
            identiFier: s.identiFier,
            name: s.name,
            publisher: s.publisher,
            trayimagefile: basename(s.trayImageFile),
            publisheremail: s.publisherEmail,
            publisherwebsite: s.publisherWebsite,
            privacypolicywebsite: s.privacyPolicyWebsite,
            licenseagreementwebsite: s.licenseAgreementWebsite,
            stickerImages: stickerImageList);
      } on PlatformException catch (e) {
        print(e.details);
      }
      setState(() {
        isDownloading = true;
        if (!downloadList.contains(s.identiFier)) {
          downloadList.add(s.identiFier);
        }
      });
    } else {
      print("not");
    }
  }

  Future<void> showDialogs(context) {
    AlertDialog s = AlertDialog(
      content: Row(
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(
            width: 10,
          ),
          Text("Downloading..."),
        ],
      ),
    );
    return showDialog(
      context: context,
      builder: (context) {
        return s;
      },
    );
  }
}
