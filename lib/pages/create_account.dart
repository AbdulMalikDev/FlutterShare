import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttershare/widgets/header.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final snackbarKey = GlobalKey<ScaffoldState>();
  final  formkey = GlobalKey<FormState>();
  String username; 

  submit()
  { var _form = formkey.currentState;
      if(_form.validate())
      {
        _form.save();
        SnackBar snackBar = SnackBar(content: Text("Welcome $username!"),);
        snackbarKey.currentState.showSnackBar(snackBar);
        Timer(Duration(seconds:2),(){
        Navigator.pop(context,username);
        });
        
      } 
  }

  Future<bool> dothis() async
  {
    if(username == null)
    {
      SnackBar snackBar = SnackBar(content: Text("Please Enter your Username..."),);
      snackbarKey.currentState.showSnackBar(snackBar);
      return false;
    }
    return true;
  }


  @override
  Widget build(BuildContext parentContext) {
    return WillPopScope(
      onWillPop: dothis,
          child: Scaffold(
        key: snackbarKey,
        appBar: header(context, titleText: "Set up your profile ",removeBackButton: true,),
        body: ListView(
          children: <Widget>[
            Container(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(top: 25),
                    child: Center(
                      child: Text(
                        "Enter a Username",
                        style: TextStyle(fontSize: 25),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Container(
                      child: Form(
                        autovalidate: true,
                        key: formkey,
                        child: TextFormField(
                          validator: (val) {
                            if(val.trim().length<3||val.isEmpty)
                            {
                              return "Username too short";
                            }else if(val.trim().length>12)
                            {
                              return "Username too long";
                            }else{
                              return null;
                            }
                          },
                          onSaved: (val) => username = val,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelStyle: TextStyle(fontSize: 15),
                              labelText: "username",
                              hintText: "Must be atleast 3 characters"),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: submit,
                    child: Container(
                      height: 50,
                      width: 350,
                      decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(7)),
                      child: Center(
                        child: Text(
                          "Submit",
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
