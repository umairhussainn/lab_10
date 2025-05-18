import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html if (dart.library.io) 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:typed_data';

// 1. Entry Point - Fixed main() function
void main() {
runApp(SocialMediaApp());
}

class SocialMediaApp extends StatelessWidget {
@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'Social Media App',
theme: ThemeData(
primarySwatch: Colors.blue,
visualDensity: VisualDensity.adaptivePlatformDensity,
),
home: FeedScreen(),
debugShowCheckedModeBanner: false,
);
}
}

// 2. Post Model
class Post {
String id;
String title;
String description;
dynamic image; // Can be File (mobile) or html.File (web)

Post({
required this.id,
required this.title,
required this.description,
this.image,
});
}

// 3. Feed Screen
class FeedScreen extends StatefulWidget {
@override
_FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
List<Post> posts = [];

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: Text('Social Feed'),
actions: [
IconButton(
icon: Icon(Icons.add),
onPressed: () async {
final newPost = await Navigator.push(
context,
MaterialPageRoute(builder: (context) => PostScreen()),
);
if (newPost != null) {
setState(() {
posts.add(newPost);
});
}
},
),
],
),
body: posts.isEmpty
? Center(
child: Text(
'No posts yet. Tap + to add one!',
style: TextStyle(fontSize: 18),
),
)
    : ListView.builder(
itemCount: posts.length,
itemBuilder: (context, index) {
return PostCard(
post: posts[index],
onDelete: () => _confirmDelete(index),
onEdit: () async {
final updatedPost = await Navigator.push(
context,
MaterialPageRoute(
builder: (context) => PostScreen(post: posts[index]),
),
);
if (updatedPost != null) {
setState(() {
posts[index] = updatedPost;
});
}
},
);
},
),
);
}

void _confirmDelete(int index) {
showDialog(
context: context,
builder: (context) => AlertDialog(
title: Text('Delete Post'),
content: Text('Are you sure you want to delete this post?'),
actions: [
TextButton(
child: Text('No'),
onPressed: () => Navigator.pop(context),
),
TextButton(
child: Text('Yes'),
onPressed: () {
setState(() {
posts.removeAt(index);
});
Navigator.pop(context);
_showToast('Post deleted successfully');
},
),
],
),
);
}

void _showToast(String message) {
Fluttertoast.showToast(
msg: message,
toastLength: Toast.LENGTH_SHORT,
gravity: ToastGravity.BOTTOM,
);
}
}

// 4. Post Card Widget
class PostCard extends StatelessWidget {
final Post post;
final VoidCallback onDelete;
final VoidCallback onEdit;

const PostCard({
required this.post,
required this.onDelete,
required this.onEdit,
});

@override
Widget build(BuildContext context) {
return Card(
margin: EdgeInsets.all(8),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Padding(
padding: EdgeInsets.all(12),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(
post.title,
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
),
),
Row(
children: [
IconButton(
icon: Icon(Icons.edit, color: Colors.blue),
onPressed: onEdit,
),
IconButton(
icon: Icon(Icons.delete, color: Colors.red),
onPressed: onDelete,
),
],
),
],
),
),
Padding(
padding: EdgeInsets.symmetric(horizontal: 12),
child: Text(post.description),
),
if (post.image != null) _buildImagePreview(context),
SizedBox(height: 12),
],
),
);
}

Widget _buildImagePreview(BuildContext context) {
return GestureDetector(
onLongPress: () => _downloadImage(context),
child: Padding(
padding: EdgeInsets.all(12),
child: ClipRRect(
borderRadius: BorderRadius.circular(8),
child: _buildImageWidget(),
),
),
);
}

Widget _buildImageWidget() {
if (kIsWeb) {
// Web image display
if (post.image != null) {
final imageUrl = html.Url.createObjectUrl(post.image);
return Image.network(
imageUrl,
height: 200,
width: double.infinity,
fit: BoxFit.cover,
errorBuilder: (context, error, stackTrace) {
return Icon(Icons.error);
},
);
}
return SizedBox.shrink();
} else {
// Mobile image display
return Image.file(
post.image as File,
height: 200,
width: double.infinity,
fit: BoxFit.cover,
);
}
}

Future<void> _downloadImage(BuildContext context) async {
if (kIsWeb) {
// Web download implementation
try {
final reader = html.FileReader();
reader.readAsDataUrl(post.image);
await reader.onLoad.first;

final anchor = html.AnchorElement()
..href = reader.result as String
..download = 'post_${post.id}.jpg'
..style.display = 'none';

html.document.body?.append(anchor);
anchor.click();
anchor.remove();

_showToast('Image downloaded successfully!');
} catch (e) {
_showToast('Failed to download image');
}
} else {
// Mobile download implementation
try {
final directory = await getApplicationDocumentsDirectory();
final imagePath = '${directory.path}/${post.id}.jpg';
await (post.image as File).copy(imagePath);
_showToast('Image downloaded successfully!');
} catch (e) {
_showToast('Failed to download image');
}
}
}

void _showToast(String message) {
Fluttertoast.showToast(
msg: message,
toastLength: Toast.LENGTH_SHORT,
);
}
}

// 5. Post Screen (Create/Edit)
class PostScreen extends StatefulWidget {
final Post? post;

const PostScreen({this.post});

@override
_PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
final _formKey = GlobalKey<FormState>();
late TextEditingController _titleController;
late TextEditingController _descriptionController;
dynamic _image;
bool _isEditing = false;

@override
void initState() {
super.initState();
_isEditing = widget.post != null;
_titleController = TextEditingController(
text: _isEditing ? widget.post!.title : '',
);
_descriptionController = TextEditingController(
text: _isEditing ? widget.post!.description : '',
);
_image = _isEditing ? widget.post!.image : null;
}

@override
void dispose() {
_titleController.dispose();
_descriptionController.dispose();
super.dispose();
}

Future<void> _pickImage() async {
final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
if (pickedFile != null) {
setState(() {
if (kIsWeb) {
_image = pickedFile;
} else {
_image = File(pickedFile.path);
}
});
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: Text(_isEditing ? 'Edit Post' : 'Create Post'),
),
body: SingleChildScrollView(
padding: EdgeInsets.all(16),
child: Form(
key: _formKey,
child: Column(
children: [
TextFormField(
controller: _titleController,
decoration: InputDecoration(
labelText: 'Title',
border: OutlineInputBorder(),
),
validator: (value) =>
value!.isEmpty ? 'Please enter a title' : null,
),
SizedBox(height: 16),
TextFormField(
controller: _descriptionController,
decoration: InputDecoration(
labelText: 'Description',
border: OutlineInputBorder(),
),
maxLines: 3,
validator: (value) =>
value!.isEmpty ? 'Please enter a description' : null,
),
SizedBox(height: 16),
ElevatedButton(
onPressed: _pickImage,
child: Text(_image == null ? 'Select Image' : 'Change Image'),
),
SizedBox(height: 16),
if (_image != null) _buildImagePreview(),
SizedBox(height: 24),
ElevatedButton(
onPressed: _submitPost,
child: Text(_isEditing ? 'Update Post' : 'Create Post'),
style: ElevatedButton.styleFrom(
minimumSize: Size(double.infinity, 50),
),
),
],
),
),
),
);
}

Widget _buildImagePreview() {
return Column(
children: [
Text(
'Image Preview:',
style: TextStyle(fontWeight: FontWeight.bold),
),
SizedBox(height: 8),
_buildImageWidget(),
],
);
}

Widget _buildImageWidget() {
if (kIsWeb) {
if (_image != null) {
final imageUrl = html.Url.createObjectUrl(_image);
return Image.network(
imageUrl,
height: 200,
width: double.infinity,
fit: BoxFit.cover,
);
}
return SizedBox.shrink();
} else {
return Image.file(
_image as File,
height: 200,
width: double.infinity,
fit: BoxFit.cover,
);
}
}

void _submitPost() {
if (_formKey.currentState!.validate()) {
final post = Post(
id: _isEditing ? widget.post!.id : DateTime.now().millisecondsSinceEpoch.toString(),
title: _titleController.text,
description: _descriptionController.text,
image: _image,
);
Navigator.pop(context, post);
_showToast(_isEditing ? "Post updated!" : "Post created!");
}
}

void _showToast(String message) {
Fluttertoast.showToast(
msg: message,
toastLength: Toast.LENGTH_SHORT,
);
}
}