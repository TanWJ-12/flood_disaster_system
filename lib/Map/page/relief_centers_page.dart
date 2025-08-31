
import 'package:flutter/material.dart';
import 'package:fyp/Map/page/add_relief_center_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ReliefCentersPage extends StatefulWidget {
	const ReliefCentersPage({super.key});

	@override
	State<ReliefCentersPage> createState() => _ReliefCentersPageState();
}

class _ReliefCentersPageState extends State<ReliefCentersPage> {
	bool _isAdmin = false;
	bool _loading = true;

	@override
	void initState() {
		super.initState();
		_checkAdmin();
	}

	Future<void> _checkAdmin() async {
		final user = FirebaseAuth.instance.currentUser;
		if (user == null) {
			setState(() {
				_isAdmin = false;
				_loading = false;
			});
			return;
		}
		final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
		final role = doc.data()?['role'];
		setState(() {
			_isAdmin = role == 'admin';
			_loading = false;
		});
	}


		@override
		Widget build(BuildContext context) {
			return Scaffold(
				appBar: AppBar(
					title: const Text('Relief Centers Map'),
					leading: _loading
							? null
							: _isAdmin
									? IconButton(
											icon: const Icon(Icons.add_location_alt),
											tooltip: 'Add Relief Center',
											onPressed: () {
												Navigator.of(context).push(
													MaterialPageRoute(
														builder: (ctx) => AddReliefCenterPage(),
													),
												);
											},
										)
									: null,
				),
				body: Center(
					child: Text('Map of Relief Centers will be shown here.'),
				),
			);
		}
	}
