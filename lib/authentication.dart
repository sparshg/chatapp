import 'package:chatapp/database.dart';
import 'package:chatapp/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'applicationstate.dart';
import 'widgets.dart';

enum ApplicationLoginState {
  emailAddress,
  register,
  password,
  loggedIn,
}

class Authentication extends StatelessWidget {
  const Authentication({
    Key? key,
    required this.loginState,
    required this.email,
    required this.startLoginFlow,
    required this.verifyEmail,
    required this.signInWithEmailAndPassword,
    required this.cancelRegistration,
    required this.registerAccount,
    required this.signOut,
  }) : super(key: key);

  final ApplicationLoginState loginState;
  final String? email;
  final void Function() startLoginFlow;
  final void Function(
    String email,
    void Function(Exception e) error,
  ) verifyEmail;
  final void Function(
    String email,
    String password,
    void Function(Exception e) error,
  ) signInWithEmailAndPassword;
  final void Function() cancelRegistration;
  final void Function(
    String email,
    String displayName,
    String password,
    void Function(Exception e) error,
  ) registerAccount;
  final void Function() signOut;

  @override
  Widget build(BuildContext context) {
    switch (loginState) {
      case ApplicationLoginState.emailAddress:
        return EmailForm(
            callback: (email) => verifyEmail(
                email, (e) => _showErrorDialog(context, 'Invalid email', e)));
      case ApplicationLoginState.password:
        return PasswordForm(
          email: email!,
          login: (email, password) {
            signInWithEmailAndPassword(email, password,
                (e) => _showErrorDialog(context, 'Failed to sign in', e));
          },
        );
      case ApplicationLoginState.register:
        return RegisterForm(
          email: email!,
          cancel: () {
            cancelRegistration();
          },
          registerAccount: (
            email,
            displayName,
            password,
          ) {
            registerAccount(
                email,
                displayName,
                password,
                (e) =>
                    _showErrorDialog(context, 'Failed to create account', e));
          },
        );
      case ApplicationLoginState.loggedIn:
        return const Main();
      default:
        return Row(
          children: const [
            Text("Internal error, this shouldn't happen..."),
          ],
        );
    }
  }

  void _showErrorDialog(BuildContext context, String title, Exception e) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontSize: 24),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  '${(e as dynamic).message}',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            StyledButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.deepPurple),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SearchController {
  void Function(String s) callback = (String s) {};
}

class Main extends StatefulWidget {
  const Main({Key? key}) : super(key: key);
  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  final _controller = TextEditingController();
  final s = _SearchController();
  TextEditingController message = TextEditingController();
  final FocusNode focusNode = FocusNode();

  int page = 1;
  bool dm = false;

  Widget showUsers() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(20),
                filled: true,
                hintStyle: TextStyle(color: Colors.grey[600]),
                hintText: "Search",
                fillColor: Colors.grey.shade200),
            controller: _controller,
            onChanged: (String st) => s.callback(st),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Center(
                child: StreamBuilder<QuerySnapshot>(
                  stream: Database.retrieveUsers(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return const Text("Error");
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    final data = snapshot.requireData;

                    return People(
                        controller: s,
                        snapshot: data,
                        quit: () => setState(() => page = 1));
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
  void showChat(String roomid, String roomname) {
    final ScrollController _controller = ScrollController();
    void _scrollDown() {
      _controller.animateTo(
        _controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
      );
    }

    Navigator.push(context,
        MaterialPageRoute<void>(builder: (BuildContext context) {
      return SafeArea(
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey.shade300,
                        radius: 25,
                        child: IconButton(
                          onPressed: () =>
                              setState(() => Navigator.pop(context)),
                          icon: const Icon(Icons.arrow_back),
                        ),
                      ),
                      FittedBox(
                        child: Container(
                          padding: const EdgeInsets.all(5.0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40.0),
                              color: Colors.grey.shade300),
                          child: IconAndDetail(Icons.person, roomname),
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.grey.shade300,
                        radius: 25,
                        child: IconButton(
                          onPressed: () => Database.deleteRoom(roomid).then(
                              (_) => setState(() => Navigator.pop(context))),
                          icon: Icon(Icons.delete,
                              color: Colors.redAccent.shade700),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                        stream: Database.retrieveChats(roomid, dm),
                        builder: (BuildContext context,
                            AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.hasError) {
                            return const Text("");
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final data = snapshot.requireData.docs;
                          WidgetsBinding.instance
                              .addPostFrameCallback((_) => _scrollDown());
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: ListView.builder(
                                controller: _controller,
                                physics: const BouncingScrollPhysics(),
                                itemCount: data.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      mainAxisAlignment: data[index]
                                                  ['sendBy'] ==
                                              Provider.of<ApplicationState>(
                                                      context,
                                                      listen: false)
                                                  .name
                                          ? MainAxisAlignment.end
                                          : MainAxisAlignment.start,
                                      children: [
                                        if (data[index]['sendBy'] ==
                                            Provider.of<ApplicationState>(
                                                    context,
                                                    listen: false)
                                                .name)
                                          const Spacer(),
                                        Flexible(
                                          flex: 3,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 15.0, vertical: 10),
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(25.0),
                                                color: Colors.grey.shade300),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Wrap(
                                                  children: [
                                                    const Icon(Icons.person),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      data[index]['sendBy'],
                                                      style: const TextStyle(
                                                          fontSize: 16),
                                                    ),
                                                    const SizedBox(width: 6),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  data[index]['message'],
                                                  style: const TextStyle(
                                                      fontSize: 18),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (data[index]['sendBy'] !=
                                            Provider.of<ApplicationState>(
                                                    context,
                                                    listen: false)
                                                .name)
                                          const Spacer()
                                      ],
                                    ),
                                  );
                                }),
                          );
                        }),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 25, vertical: 10),
                            filled: true,
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            hintText: "Message",
                            fillColor: Colors.grey.shade300,
                          ),
                          controller: message,
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        backgroundColor: Colors.grey.shade300,
                        radius: 25,
                        child: IconButton(
                          onPressed: () {
                            setState(() => pushMessage(roomid));
                            FocusScope.of(context).requestFocus(focusNode);
                          },
                          icon: const Icon(Icons.send_rounded),
                        ),
                      ),
                    ],
                  ),
                ]),
          ),
        ),
      );
    }));
  }

  void pushMessage(String roomid) {
    if (message.text.isEmpty) return;
    Database.pushMessage(message.text, roomid, dm);
    message.text = "";
  }

  Widget showMain() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                    onPressed: () => setState(() => page = 2),
                    icon: const Icon(Icons.add),
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      onPrimary: Colors.grey.shade800,
                      primary: Colors.grey.shade200,
                      elevation: 1,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    label: const Text("Add Chat",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500))),
              ),
              SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                    onPressed: () => setState(() => dm = !dm),
                    icon: Icon(dm ? Icons.group : Icons.message_rounded),
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      onPrimary: Colors.grey.shade800,
                      primary: Colors.grey.shade200,
                      elevation: 1,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    label: Text(dm ? "Show Rooms" : "Show DMs",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500))),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Center(
                child: StreamBuilder<QuerySnapshot>(
                  stream: Database.retrieveRooms(dm),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    final data = snapshot.data!.docs;
                    if (snapshot.hasError || data.isEmpty) {
                      return Column(
                        children: [
                          const Spacer(),
                          const Icon(Icons.add,
                              size: 256,
                              color: Color.fromARGB(255, 200, 200, 200)),
                          Text(
                            "Rooms not found\n",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey.shade500),
                          ),
                          const Spacer(flex: 2),
                        ],
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: data.length,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        String title = dm
                            ? data[index]['users']
                                .where((i) =>
                                    i !=
                                    FirebaseAuth
                                        .instance.currentUser!.displayName!)
                                .single
                            : data[index]['groupName'];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(title),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 24),
                            onTap: () {
                              showChat(data[index].id, title);
                            },
                          ),
                          color: Colors.grey.shade200,
                          margin: const EdgeInsets.only(bottom: 4),
                          shape: RoundedRectangleBorder(
                              borderRadius: index == data.length - 1
                                  ? Styles.bottomListBorder
                                  : BorderRadius.circular(0)),
                          elevation: 0,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return page == 1 ? showMain() : showUsers();
  }
}

class People extends StatefulWidget {
  const People(
      {Key? key,
      required this.controller,
      required this.snapshot,
      required this.quit})
      : super(key: key);
  final QuerySnapshot<Object?> snapshot;
  final _SearchController controller;
  final void Function() quit;

  @override
  State<StatefulWidget> createState() => _PeopleState();
}

class Popup extends StatefulWidget {
  const Popup({Key? key, this.val = '', required this.callback})
      : super(key: key);
  final String val;
  final void Function(String) callback;

  @override
  State<Popup> createState() => _PopupState();
}

class _PopupState extends State<Popup> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.value = TextEditingValue(text: widget.val);
    _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length));

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              "Enter Room name",
              style: TextStyle(fontSize: 36),
            ),
            TextField(
              controller: _controller,
              autofocus: true,
              onSubmitted: (String value) {
                widget.callback(value);
                Navigator.of(context).pop();
              },
            )
          ],
        ),
      ),
    );
  }
}

class _PeopleState extends State<People> {
  String? search;
  List<int> selected = [];

  @override
  void initState() {
    super.initState();
    widget.controller.callback = (String s) => setState(() => search = s);
  }

  @override
  Widget build(BuildContext context) {
    var data = widget.snapshot.docs;
    data.removeWhere(
        (user) => user.id == FirebaseAuth.instance.currentUser!.uid);
    if (search != null) {
      data = data
          .where((user) =>
              user["userName"].toLowerCase().contains(search?.toLowerCase()))
          .toList();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: data.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(data[index]["userName"]),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                    onTap: () {
                      if (!selected.contains(index)) {
                        setState(() => selected.add(index));
                      } else {
                        setState(() => selected.remove(index));
                      }
                    },
                  ),
                  color: selected.contains(index)
                      ? const Color.fromARGB(255, 210, 210, 210)
                      : Colors.grey.shade200,
                  margin: const EdgeInsets.only(bottom: 4),
                  shape: RoundedRectangleBorder(
                      borderRadius: index == data.length - 1
                          ? Styles.bottomListBorder
                          : BorderRadius.circular(0)),
                  elevation: 0,
                );
              }),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: selected.isEmpty ? 0 : 50,
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: ElevatedButton.icon(
              onPressed: () {
                if (selected.length == 1) {
                  Database.createDm(data[selected[0]]['userEmail'])
                      .then((_) => widget.quit());
                  return;
                }
                showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  builder: (BuildContext context) => Padding(
                    padding: MediaQuery.of(context).viewInsets,
                    child: Popup(callback: (name) {
                      Database.createRoom(
                              FirebaseAuth.instance.currentUser!.uid,
                              FirebaseAuth.instance.currentUser!.displayName!,
                              selected.map((i) => data[i].id).toList(),
                              selected
                                  .map((i) => data[i]['userName'] as String)
                                  .toList(),
                              name)
                          .then((_) => widget.quit());
                    }),
                  ),
                );
              },
              icon: const Icon(Icons.check),
              style: ElevatedButton.styleFrom(
                  onPrimary: Colors.grey.shade200,
                  primary: Colors.green.shade300,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(50)),
              label: const Text("")),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: selected.isEmpty ? 50 : 0,
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: ElevatedButton.icon(
              onPressed: () {
                widget.quit();
              },
              icon: const Icon(Icons.close),
              style: ElevatedButton.styleFrom(
                  onPrimary: Colors.grey.shade200,
                  primary: Colors.red.shade300,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(50)),
              label: const Text("")),
        ),
      ],
    );
  }
}

class EmailForm extends StatefulWidget {
  const EmailForm({Key? key, required this.callback}) : super(key: key);
  final void Function(String email) callback;
  @override
  _EmailFormState createState() => _EmailFormState();
}

class _EmailFormState extends State<EmailForm> {
  final _formKey = GlobalKey<FormState>(debugLabel: '_EmailFormState');
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        const Header('Sign in'),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextFormField(
                    controller: _controller,
                    decoration: Styles.textDecoration('Enter your email'),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter your email address to continue';
                      }
                      return null;
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 30),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(width: 1, color: Colors.grey.shade700),
                        ),
                        child: IconButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              widget.callback(_controller.text);
                            }
                          },
                          icon: Icon(Icons.login, color: Colors.grey.shade700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}

class RegisterForm extends StatefulWidget {
  const RegisterForm({
    Key? key,
    required this.registerAccount,
    required this.cancel,
    required this.email,
  }) : super(key: key);
  final String email;
  final void Function(String email, String displayName, String password)
      registerAccount;
  final void Function() cancel;
  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>(debugLabel: '_RegisterFormState');
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        const Header('Choose a password'),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: TextFormField(
                    controller: _displayNameController,
                    decoration: Styles.textDecoration('Username'),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter your account name';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: TextFormField(
                    controller: _passwordController,
                    decoration: Styles.textDecoration('Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter your password';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Button(callback: widget.cancel, text: "Cancel"),
                      const SizedBox(width: 16),
                      Button(
                          callback: () {
                            if (_formKey.currentState!.validate()) {
                              widget.registerAccount(
                                _emailController.text,
                                _displayNameController.text,
                                _passwordController.text,
                              );
                            }
                          },
                          text: "Save"),
                      const SizedBox(width: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}

class PasswordForm extends StatefulWidget {
  const PasswordForm({
    Key? key,
    required this.login,
    required this.email,
  }) : super(key: key);
  final String email;
  final void Function(String email, String password) login;
  @override
  _PasswordFormState createState() => _PasswordFormState();
}

class _PasswordFormState extends State<PasswordForm> {
  final _formKey = GlobalKey<FormState>(debugLabel: '_PasswordFormState');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        const Header('Enter your password'),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: TextFormField(
                    controller: _emailController,
                    decoration: Styles.textDecoration("Enter your email"),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter your email address to continue';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: TextFormField(
                    controller: _passwordController,
                    decoration: Styles.textDecoration("Password"),
                    obscureText: true,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter your password';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(width: 16),
                      Button(
                          callback: () {
                            if (_formKey.currentState!.validate()) {
                              widget.login(
                                _emailController.text,
                                _passwordController.text,
                              );
                            }
                          },
                          text: "Sign in"),
                      const SizedBox(width: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}
