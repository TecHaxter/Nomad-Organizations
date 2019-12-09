import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nomad/services/auth_provider.dart';
import './auth.dart';


class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _LoginPageState();
}


class _LoginPageState extends State<LoginPage>
{
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _uid;
  String _email;
  String _password;
  String _institute_postfix;
  bool _passwordVisible = true;

  String _errorMessage = "";
  bool _isLoading = false; 


  bool validateAndSave() {
    final form = _formKey.currentState;
    if(form.validate()) {
      form.save();
      return true;
    } else {
      return false;
    }
  }

  validateAndSubmit() async{
    if(validateAndSave()) {
      setState(() {
        _errorMessage = "";
        _isLoading = true; 
      });
      String user;
      try {
        final BaseAuth auth = AuthProvider.of(context).auth;
        _email = _uid + _institute_postfix;
        user = await auth.signInWithEmailAndPassword(_email, _password);
        print("Signed in: {$user.uid}");
      }
      catch (e) {
      print("Error: $e");
      setState(() {
        _isLoading = false;
         _errorMessage = e.message;
      });
      }
    } 
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Nomad"),
      ),
      body: new SingleChildScrollView(
        padding: EdgeInsets.only(top: 25.0),
        child: Container(
          padding: EdgeInsets.all(25.0),
          child: new Form(
            key: _formKey,
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: signInForm() + _showCircularProgress(),
            ),
          ),    
        ),
      )
    );
  }

  List<Widget> _showCircularProgress(){
    if (_isLoading) {
      return [Center(child: CircularProgressIndicator(backgroundColor: Colors.black,))];
    } return [Container(height: 0.0, width: 0.0,)];
  }

  _showErrorMessage() {
    if (_errorMessage.length > 0 && _errorMessage != null) {
      return new AlertDialog(
            title: new Text("Invalid User ID or Password !!", textAlign: TextAlign.center,),
            content: new Text(_errorMessage, textAlign: TextAlign.center,),
          );
    } return Container(height: 0.0, width: 0.0,);
  }

  List<Widget> signInForm() {
    return [
      Text(
        "Login Panel",
        style: TextStyle(fontSize: 30.0),
      ),
      Padding(
        padding: EdgeInsets.only(bottom: 10.0),
      ),
      instituteDropDown(),
      Padding(
        padding: EdgeInsets.only(bottom: 10.0),
      ),
      TextFormField(
        validator: (value) => value.isEmpty ? "UID can't be empty !!" : null,
        onSaved: (value) => _uid = value,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius:BorderRadius.circular(30.0)
          ),
          labelText: 'Unique ID'
        ),
      ),
      Padding(
        padding: EdgeInsets.only(bottom: 10.0),
      ),
      TextFormField(
        validator: (value) => value.isEmpty ? "Password can't be empty !!" : null,
        onSaved: (value) => _password = value,
        obscureText: _passwordVisible,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius:BorderRadius.circular(30.0)
          ),
        labelText: 'Password',
        suffixIcon: IconButton(
          icon: Icon(
            // Based on passwordVisible state choose the icon
              _passwordVisible
              ? Icons.visibility
              : Icons.visibility_off,
              color: Colors.grey,
              ),
          onPressed: () {
              // Update the state i.e. toogle the state of passwordVisible variable
              setState(() {
                  _passwordVisible = !_passwordVisible;
              });
            },
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.only(bottom: 10.0),
      ),
      new RaisedButton(
        padding: const EdgeInsets.all(8.0),
        textColor: Colors.white,
        color: Colors.black,
        shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
        onPressed: validateAndSubmit,
        child: new Text("Login"),
      ),
      _showErrorMessage()
    ];
  }

  Widget instituteDropDown() {
    return new StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('institutes').snapshots(),
      builder: (context, snapshot){
        if (!snapshot.hasData) return const Center(
          child: CircularProgressIndicator(backgroundColor: Colors.black,),
        );
        return DropdownButtonFormField(
          validator: (value) {
              if (value == null) {
                return "Institute can't be empty !!";
              }
            },
          value: _institute_postfix,
          onChanged: (String value) {
                setState(() {
                this._institute_postfix = value; 
                });
              },
          items: snapshot.data.documents.map((DocumentSnapshot document) {
                return new DropdownMenuItem<String>(
                  value: document.data['postfix'],
                  child: new Text(document.data['institute']),
                );
              }).toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius:BorderRadius.circular(30.0)
            ),
            labelText: 'Institute',
          ),
        );
        
      }
    );
  }


}
