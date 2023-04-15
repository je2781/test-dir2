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
      body: Container(
        height: deviceSize.height * .6,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
          image: const DecorationImage(
              fit: BoxFit.cover,
              opacity: 0.6,
              image: NetworkImage(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/Market_Square_Park.jpg/1024px-Market_Square_Park.jpg')),
        ),
        margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(10),
        child: FutureBuilder(
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (!snapshot.hasData) {
                return const Center(
                  child: Text(
                    'Start creating a new user profile',
                    softWrap: true,
                    textAlign: TextAlign.center,
                  ),
                );
              } else {
                final doc = snapshot.data;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundImage: NetworkImage(doc!['image_url']),
                      backgroundColor: Colors.grey,
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      title: Row(
                        children: [
                          const Icon(
                            Icons.person,
                            color: Colors.white,
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
                            color: Colors.white,
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
                            color: Colors.white,
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
