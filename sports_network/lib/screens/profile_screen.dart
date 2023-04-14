import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/user_info.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.centerLeft,
        margin: const EdgeInsets.only(
          top: 10,
        ),
        padding: const EdgeInsets.all(10),
        child: ChangeNotifierProvider(
          create: (_) => UserI(FirebaseAuth.instance.currentUser!),
          child: FutureBuilder(
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  final doc = snapshot.data;
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(doc!['image_url']),
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        title: Row(
                          children: [
                            const Icon(Icons.person),
                            Text(doc['username']),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            const Icon(Icons.phone),
                            Text(doc['mobile']),
                          ],
                        ),
                        trailing: Text('interested in ${doc['interest']}'),
                      )
                    ],
                  );
                }
              },
              future: Provider.of<UserI>(context, listen: false).userData),
        ),
      ),
    );
  }
}
