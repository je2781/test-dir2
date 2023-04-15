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
    //connecting to the device media
    final deviceSize = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: FutureBuilder(
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else {
                final doc = snapshot.data;
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        shape: BoxShape.rectangle,
                        image: DecorationImage(
                            fit: BoxFit.cover,
                            opacity: 0.6,
                            image: NetworkImage(
                                'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/Market_Square_Park.jpg/1024px-Market_Square_Park.jpg')),
                      ),
                      margin: const EdgeInsets.only(
                        bottom: 10.0,
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(10),
                      child: CircleAvatar(
                        radius: 70,
                        backgroundImage: NetworkImage(doc!['image_url']),
                        backgroundColor: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      title: Row(
                        children: [
                          const Icon(
                            Icons.person,
                          ),
                          const SizedBox(width: 10),
                          Chip(
                            label: Padding(
                              padding: EdgeInsets.all(4),
                              child: Text(
                                doc['username'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontFamily: 'Anton',
                                ),
                              ),
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      title: Row(
                        children: [
                          const Icon(
                            Icons.phone,
                          ),
                          const SizedBox(width: 10),
                          Chip(
                            label: Padding(
                              padding: EdgeInsets.all(4),
                              child: Text(
                                doc['mobile'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontFamily: 'Anton',
                                ),
                              ),
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      title: Row(
                        children: [
                          const Icon(
                            Icons.sports,
                          ),
                          const SizedBox(width: 10),
                          Chip(
                            label: Padding(
                              padding: EdgeInsets.all(4),
                              child: Text(
                                doc['interest'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontFamily: 'Anton',
                                ),
                              ),
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            },
            future: Provider.of<Users>(context, listen: false).userData),
      ),
    );
  }
}
