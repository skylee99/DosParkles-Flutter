import 'package:bubble/bubble.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:com.floridainc.dosparkles/actions/adapt.dart';
import 'package:com.floridainc.dosparkles/actions/api/graphql_client.dart';
import 'package:com.floridainc.dosparkles/actions/app_config.dart';
import 'package:com.floridainc.dosparkles/utils/colors.dart';
import 'package:fish_redux/fish_redux.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flui/flui.dart';

import 'dart:async';
import 'state.dart';

Widget buildView(
    ChatMessagesPageState state, Dispatch dispatch, ViewService viewService) {
  final pages = [
    BubblePage(
      chatId: state.chatId,
      userId: state.userId,
      conversationName: state.conversationName,
    )
  ];

  Widget _buildPage(Widget page) {
    return page;
  }

  return Scaffold(
    body: FutureBuilder(
        future: _checkContextInit(
          Stream<double>.periodic(Duration(milliseconds: 50),
              (x) => MediaQuery.of(viewService.context).size.height),
        ),
        builder: (_, snapshot) {
          if (snapshot.hasData) if (snapshot.data > 0) {
            Adapt.initContext(viewService.context);
            return PageView.builder(
              physics: NeverScrollableScrollPhysics(),
              controller: state.pageController,
              allowImplicitScrolling: false,
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return _buildPage(pages[index]);
              },
            );
          }
          return Container();
        }),
  );
}

Future<double> _checkContextInit(Stream<double> source) async {
  await for (double value in source) {
    if (value > 0) {
      return value;
    }
  }
  return 0.0;
}

class BubblePage extends StatefulWidget {
  final String chatId;
  final String userId;
  final String conversationName;

  const BubblePage({
    Key key,
    this.chatId = '',
    this.userId = '',
    this.conversationName = 'MedDrive',
  }) : super(key: key);

  @override
  State<BubblePage> createState() => _BubblePageState();
}

Future fetchData(String chatId) async {
  QueryResult chat = await BaseGraphQLClient.instance.fetchChat(chatId);
  return chat.data['chats'][0];
}

Stream fetchDataProcess(String chatId) async* {
  while (true) {
    yield await fetchData(chatId);
    await Future<void>.delayed(Duration(seconds: 30));
  }
}

class _BubblePageState extends State<BubblePage> {
  var formatter = new DateFormat.yMMMMd().add_jm();
  String inputData = "";
  var _controller = TextEditingController();

  String getUserLetter(item) {
    return item != null ? item['name'].toString()[0] : "";
  }

  Widget _buildBubbleContent(double maxWidth, context) {
    Widget insetV = SizedBox(height: 20);
    Widget insetVSmall = SizedBox(height: 10);
    Widget insetH = SizedBox(width: 4);
    double tWidth = maxWidth - 160;

    return StreamBuilder(
      stream: fetchDataProcess(widget.chatId),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData && !snapshot.hasError) {
          return snapshot.data['chat_messages'] == null
              ? Text('No Data', textAlign: TextAlign.center)
              : Expanded(
                  child: ListView(
                    children: snapshot.data['chat_messages']
                        .map<Widget>(
                          (item) => item['user'] != null &&
                                  widget.userId == item['user']['id']
                              ? Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        width: 300.0,
                                        constraints:
                                            BoxConstraints(minHeight: 38.0),
                                        child: Bubble(
                                          margin: BubbleEdges.only(top: 10),
                                          stick: true,
                                          color: Colors.white,
                                          nip: BubbleNip.rightBottom,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10.0),
                                            child: Text(
                                              '${item['text']}',
                                              style: TextStyle(
                                                fontSize: 16,
                                              ),
                                              softWrap: true,
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    insetVSmall,
                                    Padding(
                                      padding: EdgeInsets.only(right: 145.0),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          '${formatter.format(DateTime.parse(item['createdAt']))}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black38,
                                          ),
                                        ),
                                      ),
                                    ),
                                    insetV,
                                  ],
                                )
                              : Column(children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      insetH,
                                      item['messageType'] == 'text'
                                          ? Align(
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                width: 300.0,
                                                constraints: BoxConstraints(
                                                    minHeight: 38.0),
                                                child: Bubble(
                                                  margin:
                                                      BubbleEdges.only(top: 10),
                                                  stick: true,
                                                  color: Colors.white,
                                                  nip: BubbleNip.leftBottom,
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 10.0),
                                                    child: Text(
                                                      '${item['text']}',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                      softWrap: true,
                                                      textAlign: TextAlign.left,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : ElevatedButton(
                                              child: Text("Show order"),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        OrderWidget(
                                                            orderId:
                                                                item['order'] !=
                                                                        null
                                                                    ? item['order']
                                                                        ['id']
                                                                    : ''),
                                                  ),
                                                );
                                              },
                                            ),
                                    ],
                                  ),
                                  insetVSmall,
                                  Padding(
                                    padding: EdgeInsets.only(left: 45.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '${formatter.format(DateTime.parse(item['createdAt']))}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black38,
                                        ),
                                      ),
                                    ),
                                  ),
                                  insetV,
                                ]),
                        )
                        .toList(),
                  ),
                );
        } else {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: Adapt.screenH() / 4),
              SizedBox(
                  width: Adapt.screenW(),
                  height: Adapt.screenH() / 4,
                  child: Container(
                    child: CircularProgressIndicator(),
                    alignment: Alignment.center,
                  ))
            ],
          );
        }
      },
    );
  }

  Widget _buildRoundedAvatar(String alpha) {
    return FLAvatar(
      text: alpha,
      textStyle: TextStyle(color: Colors.white, fontSize: 18),
      width: 50,
      height: 50,
      color: HexColor("#182465"),
    );
  }

  getConversationName(conversation, userId) {
    var chatNames = [];
    var users = conversation['users'];
    for (int i = 0; i < users.length; i++) {
      if (users[i] != null && users[i]['id'] != userId) {
        chatNames.add('${users[i]['name']}');
      }
    }
    return chatNames.join(', ');
  }

  addMessage(text, chatId, userId) async {
    await BaseGraphQLClient.instance
        .createMessage({'text': text, 'chat': chatId, 'user': userId});
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData queryData = MediaQuery.of(context);
    final double width = queryData.size.width;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: 181.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [HexColor('#8FADEB'), HexColor('#7397E2')],
                begin: const FractionalOffset(0.0, 0.0),
                end: const FractionalOffset(1.0, 0.0),
                stops: [0.0, 1.0],
                tileMode: TileMode.clamp,
              ),
            ),
          ),
        ),
        Scaffold(
          appBar: AppBar(
            title: Text('${widget.conversationName}'),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            leadingWidth: 70.0,
            automaticallyImplyLeading: false,
            leading: InkWell(
              child: Image.asset("images/back_button.png"),
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.only(top: 10, left: 8.0, right: 8.0),
            decoration: BoxDecoration(
              color: HexColor("#FAFCFF"),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32.0),
                topRight: Radius.circular(32.0),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 136.0,
                  height: 28.0,
                  decoration: BoxDecoration(
                    color: HexColor("#EAECF2"),
                    borderRadius: BorderRadius.circular(17.0),
                  ),
                  child: Center(
                      child: Text(
                    "November 16",
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                    ),
                  )),
                ),
                SizedBox(height: 18.0),
                _buildBubbleContent(width, context),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            height: 80,
            color: HexColor("#182465"),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      child: TextField(
                        controller: _controller,
                        onChanged: (text) {
                          this.inputData = text;
                        },
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter message',
                          fillColor: Colors.white,
                          hintStyle: new TextStyle(color: Colors.grey),
                          labelStyle: new TextStyle(color: Colors.white),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                      width: MediaQuery.of(context).size.width * 0.5,
                    ),
                    Container(
                      width: 60,
                      height: 40,
                      child: InkWell(
                        onTap: () {
                          if (this.inputData != "") {
                            addMessage(
                              this.inputData,
                              widget.chatId,
                              widget.userId,
                            );
                            this.inputData = "";
                            _controller.clear();
                          }
                        },
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class OrderWidget extends StatefulWidget {
  final orderId;

  const OrderWidget({Key key, this.orderId}) : super(key: key);

  @override
  _OrderWidgetState createState() => _OrderWidgetState();
}

class _OrderWidgetState extends State<OrderWidget> {
  Future getInitialData() async {
    QueryResult result =
        await BaseGraphQLClient.instance.fetchOrder(widget.orderId);
    return result.data['orders'][0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: new BoxDecoration(
            gradient: new LinearGradient(
              colors: [HexColor('#3D9FB0'), HexColor('#557084')],
              begin: const FractionalOffset(0.5, 0.5),
              end: const FractionalOffset(0.5, 1.0),
              stops: [0.0, 1.0],
              tileMode: TileMode.clamp,
            ),
          ),
        ),
      ),
      body: Container(
        color: HexColor('#3D9FB0'),
        width: double.infinity,
        height: double.infinity,
        child: FutureBuilder(
          future: getInitialData(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData && !snapshot.hasError) {
              List<dynamic> products = snapshot.data['products'];

              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 5.0),
                        height: 200.0 * products.length,
                        child: ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (_, index) {
                            return Container(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.0, vertical: 10.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        products[index] != null &&
                                                AppConfig.instance.baseApiHost +
                                                        products[index]
                                                                ['thumbnail']
                                                            ['url'] !=
                                                    null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                child: new CachedNetworkImage(
                                                  imageUrl: products[index]
                                                              ['thumbnail'] !=
                                                          null
                                                      ? AppConfig.instance
                                                              .baseApiHost +
                                                          products[index]
                                                                  ['thumbnail']
                                                              ['url']
                                                      : null,
                                                  width: 100,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Container(),
                                        Expanded(
                                          child: new Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: <Widget>[
                                              Text(
                                                products[index]['name'],
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 24,
                                                    fontWeight:
                                                        FontWeight.normal),
                                              ),
                                              Text(
                                                '\$${products[index]['price']}',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 20,
                                    ),
                                    Row(children: [
                                      RichText(
                                        text: TextSpan(
                                          style: DefaultTextStyle.of(
                                            context,
                                          ).style,
                                          children: [
                                            TextSpan(
                                              text: 'Count: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 23,
                                                color: Colors.white,
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  '${snapshot.data['orderDetails'][0]['quantity']}',
                                              style: TextStyle(
                                                fontSize: 23,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Spacer(),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  OrderDetailsWidget(
                                                      product: products[index]),
                                            ),
                                          );
                                        },
                                        style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStateProperty.all<Color>(
                                            HexColor('#3D9FB0'),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Text("details"),
                                            Icon(Icons.arrow_right),
                                          ],
                                        ),
                                      ),
                                    ])
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: Adapt.screenH() / 4),
                SizedBox(
                  width: Adapt.screenW(),
                  height: Adapt.screenH() / 4,
                  child: Container(
                    child: CircularProgressIndicator(),
                    alignment: Alignment.center,
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}

class OrderDetailsWidget extends StatefulWidget {
  final product;

  const OrderDetailsWidget({Key key, this.product}) : super(key: key);

  @override
  _OrderDetailsWidgetState createState() => _OrderDetailsWidgetState();
}

class _OrderDetailsWidgetState extends State<OrderDetailsWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order details"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: new BoxDecoration(
            gradient: new LinearGradient(
              colors: [HexColor('#3D9FB0'), HexColor('#557084')],
              begin: const FractionalOffset(0.5, 0.5),
              end: const FractionalOffset(0.5, 1.0),
              stops: [0.0, 1.0],
              tileMode: TileMode.clamp,
            ),
          ),
        ),
      ),
      body: Container(
        color: HexColor('#3D9FB0'),
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: Text(
                          "Metal:",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        horizontalTitleGap: 40,
                        title: Text(
                          widget.product['properties'] != null &&
                                  widget.product['properties']['metal'] != null
                              ? widget.product['properties']['metal']
                              : "",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 24,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: Text(
                          "Type:",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        horizontalTitleGap: 40,
                        title: Text(
                          widget.product['properties'] != null &&
                                  widget.product['properties']['type'] != null
                              ? widget.product['properties']['type']
                              : "",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 24,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: Text(
                          "Shape:",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        horizontalTitleGap: 40,
                        title: Text(
                          widget.product['properties'] != null &&
                                  widget.product['properties']['shape'] != null
                              ? widget.product['properties']['shape']
                              : "",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 24,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      GridView.count(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          childAspectRatio: 1,
                          children: <Widget>[
                            for (var asset in widget.product['media'])
                              Card(
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  children: <Widget>[
                                    Image.network(
                                        '${AppConfig.instance.baseApiHost + asset['url']}'),
                                  ],
                                ),
                              ),
                          ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
