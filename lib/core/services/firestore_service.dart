import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../models/emergency_contact.dart';
import '../../models/sos_event.dart';
import '../../models/user_profile.dart';

class FirestoreService extends ChangeNotifier {
  FirebaseFirestore? get _firestore =>
      Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null;
  FirebaseAuth? get _auth =>
      Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null;

  List<EmergencyContact> _contacts = [];
  List<SosEvent> _sosEvents = [];
  UserProfile? _profile;
  String _emergencyMessage =
      'Emergency! I may need help. This is my current location: [Google Maps Link]';
  bool _notificationsEnabled = true;

  List<EmergencyContact> get contacts => List.unmodifiable(_contacts);
  List<SosEvent> get sosEvents => List.unmodifiable(_sosEvents);
  UserProfile? get profile => _profile;
  String get emergencyMessage => _emergencyMessage;
  bool get notificationsEnabled => _notificationsEnabled;

  FirestoreService() {
    _seedDemoData();
  }

  Future<void> setProfile(UserProfile profile) async {
    _profile = profile;
    notifyListeners();

    final firestore = _firestore;
    if (firestore == null) {
      return;
    }

    await firestore.collection('users').doc(profile.uid).set(profile.toMap());
  }

  Future<void> loadEmergencyContacts() async {
    final user = _auth?.currentUser;
    final firestore = _firestore;
    if (user == null || firestore == null) {
      notifyListeners();
      return;
    }

    final snapshot = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('emergencyContacts')
        .get();

    _contacts = snapshot.docs
        .map((doc) => EmergencyContact.fromMap(doc.id, doc.data()))
        .toList();
    notifyListeners();
  }

  Future<void> saveContact(EmergencyContact contact) async {
    final docContact = contact.copyWith(
      id: contact.id.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : contact.id,
    );

    _contacts = _contacts.where((item) => item.id != docContact.id).toList();
    _contacts.add(docContact);
    notifyListeners();

    final user = _auth?.currentUser;
    final firestore = _firestore;
    if (user == null || firestore == null) {
      return;
    }

    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('emergencyContacts')
        .doc(docContact.id)
        .set(docContact.toMap());
  }

  Future<void> deleteContact(String contactId) async {
    _contacts.removeWhere((contact) => contact.id == contactId);
    notifyListeners();

    final user = _auth?.currentUser;
    final firestore = _firestore;
    if (user == null || firestore == null) {
      return;
    }

    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('emergencyContacts')
        .doc(contactId)
        .delete();
  }

  Future<List<SosEvent>> loadSosHistory() async {
    final user = _auth?.currentUser;
    final firestore = _firestore;
    if (user == null || firestore == null) {
      return _sosEvents;
    }

    final snapshot = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('sosEvents')
        .get();
    _sosEvents = snapshot.docs
        .map((doc) => SosEvent.fromMap(doc.id, doc.data()))
        .toList();
    notifyListeners();
    return _sosEvents;
  }

  Future<void> createSosEvent(SosEvent event) async {
    _sosEvents.insert(0, event);
    notifyListeners();

    final user = _auth?.currentUser;
    final firestore = _firestore;
    if (user == null || firestore == null) {
      return;
    }

    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('sosEvents')
        .doc(event.id)
        .set(event.toMap());
  }

  Future<void> updateSosEventStatus(String eventId, String status) async {
    final index = _sosEvents.indexWhere((event) => event.id == eventId);
    if (index >= 0) {
      final event = _sosEvents[index];
      _sosEvents[index] = SosEvent(
        id: event.id,
        createdAt: event.createdAt,
        latitude: event.latitude,
        longitude: event.longitude,
        locationUrl: event.locationUrl,
        status: status,
        message: event.message,
        contactsNotified: event.contactsNotified,
      );
      notifyListeners();
    }

    final user = _auth?.currentUser;
    final firestore = _firestore;
    if (user == null || firestore == null) {
      return;
    }

    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('sosEvents')
        .doc(eventId)
        .update({'status': status});
  }

  void setEmergencyMessage(String value) {
    _emergencyMessage = value;
    notifyListeners();
  }

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  void _seedDemoData() {
    _contacts = [
      EmergencyContact(
        id: 'contact-1',
        name: 'Maya Patel',
        phone: '+1 555 010 1234',
        relationship: 'Partner',
        isEmergencyContact: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      EmergencyContact(
        id: 'contact-2',
        name: 'Leo Johnson',
        phone: '+1 555 010 9876',
        relationship: 'Brother',
        isEmergencyContact: true,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];

    _sosEvents = [
      SosEvent(
        id: 'event-1',
        createdAt: DateTime.now().subtract(const Duration(hours: 18)),
        latitude: 40.7128,
        longitude: -74.0060,
        locationUrl:
            'https://www.google.com/maps/search/?api=1&query=40.7128,-74.0060',
        status: 'resolved',
        message: 'Emergency! I may need help. This is my current location: https://maps.google.com/?q=40.7128,-74.0060',
        contactsNotified: ['+1 555 010 1234', '+1 555 010 9876'],
      ),
    ];
  }
}
