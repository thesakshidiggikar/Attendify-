class User {
  final String id;
  final String name;
  final String role;
  final String? token;
  
  User({
    required this.id, 
    required this.name, 
    required this.role,
    this.token,
  });
}