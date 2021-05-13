import 'dart:ui';

import 'package:com.floridainc.dosparkles/actions/api/graphql_client.dart';
import 'package:com.floridainc.dosparkles/globalbasestate/store.dart';
import 'package:com.floridainc.dosparkles/utils/colors.dart';
import 'package:com.floridainc.dosparkles/widgets/connection_lost.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

Future _fetchData() async {
  QueryResult result = await BaseGraphQLClient.instance.fetchAppContent();
  if (result.hasException) print(result.exception);

  return result.data['appContent']['termsAndConditions'];
}

class TermsContitions extends StatefulWidget {
  @override
  _TermsContitionsState createState() => _TermsContitionsState();
}

class _TermsContitionsState extends State<TermsContitions> {
  bool _isLostConnection = false;

  checkInternetConnectivity() {
    String _connectionStatus = GlobalStore.store.getState().connectionStatus;
    if (_connectionStatus == 'ConnectivityResult.none') {
      setState(() {
        _isLostConnection = true;
      });
    } else {
      setState(() {
        _isLostConnection = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    checkInternetConnectivity();

    return Container(
      color: HexColor("#F2F6FA"),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            width: MediaQuery.of(context).size.width,
            child: Image.asset(
              "images/background_lines_top.png",
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            width: MediaQuery.of(context).size.width,
            child: Image.asset(
              "images/background_lines_bottom.png",
              fit: BoxFit.contain,
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              centerTitle: true,
              elevation: 0.0,
              leadingWidth: 70.0,
              automaticallyImplyLeading: true,
              leading: InkWell(
                child: Image.asset("images/back_button.png"),
                onTap: () => Navigator.of(context).pop(),
              ),
              backgroundColor: Colors.transparent,
              title: Text(
                'Terms and Conditions',
                style: TextStyle(
                  fontSize: 22,
                  color: HexColor("#53586F"),
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.enable('smcp')],
                ),
              ),
            ),
            body: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Colors.white,
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.0),
                    FutureBuilder(
                      future: _fetchData(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && !snapshot.hasError) {
                          return Text(
                            snapshot.data,
                            style: TextStyle(fontSize: 16.0),
                          );
                        }
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    ),
                    SizedBox(height: 20.0),
                  ],
                ),
              ),
            ),
          ),
          if (_isLostConnection) ConnectionLost(),
        ],
      ),
    );
  }
}
