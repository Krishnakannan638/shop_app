import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _loading = false;
  String? _error;

  void performLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final HttpLink link = HttpLink("http://localhost:3000/shop-api");

    final GraphQLClient client = GraphQLClient(
      link: link,
      cache: GraphQLCache(store: HiveStore()),
    );

    const String mutation = """
      mutation Login(\$username: String!, \$password: String!, \$rememberMe: Boolean) {
        login(username: \$username, password: \$password, rememberMe: \$rememberMe) {
          ... on CurrentUser {
            id
            identifier
          }
          ... on NativeAuthError {
            errorCode
            message
          }
        }
      }
    """;

    try {
      final QueryResult result = await client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {
            "username": _usernameController.text,
            "password": _passwordController.text,
            "rememberMe": _rememberMe,
          },
        ),
      );

      if (result.hasException) {
        setState(() {
          _error = result.exception.toString();
          _loading = false;
        });
        return;
      }

      final data = result.data?['login'];
      if (data != null && data['id'] != null) {
        // Successfully authenticated
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Login Successful"),
            content: Text("Welcome, ${data['identifier']}!"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        // Error returned by the mutation
        setState(() {
          _error = data?['message'] ?? "An unknown error occurred.";
        });
      }
    } catch (e) {
      setState(() {
        _error = "An error occurred: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Username Field
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Password Field
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            // Remember Me Checkbox
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                ),
                const Text("Remember Me"),
              ],
            ),
            const SizedBox(height: 16),
            // Error Message
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            // Login Button
            ElevatedButton(
              onPressed: _loading ? null : performLogin,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
