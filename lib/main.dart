import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:http/http.dart' as http;

void main() => runApp(QuickMeals());

class QuickMeals extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "QuickMeals",
      home: Home(title: "QuickMeals"),
    );
  }
}

class Home extends StatefulWidget {
  Home({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var random = Random();
  var keys;
  Map<String, List<Recipe>> meals = Map();

  @override
  void initState() {
    super.initState();
    var query = Firestore.instance.collection("keys").document("edamam").get();
    query.then((snapshot) {
      keys = snapshot.data;
      _fetchRecipes("breakfast");
      _fetchRecipes("lunch");
      _fetchRecipes("dinner");
    });
  }

  _fetchRecipes(mealType) async {
    setState(() => meals.remove(mealType));
    var range = random.nextInt(100);
    var request =
        "http://api.edamam.com/search?q=$mealType&app_id=${keys['appId']}&app_key=${keys['appKey']}&from=$range&to=${range + 10}";
    var response = await http.get(request);
    if (response.statusCode == 200) {
      List<Recipe> recipes = List();
      for (var item in jsonDecode(response.body)["hits"]) {
        var recipe = Recipe.fromJson(mealType, item["recipe"]);
        recipes.add(recipe);
      }
      setState(() => meals[mealType] = recipes);
    } else {
      throw Exception("Failed to load recipe.");
    }
  }

  _getRecipe(type) {
    try {
      if (meals[type].length < 2) {
        _fetchRecipes(type);
      }
      return meals[type].last;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Row(children: <Widget>[
            Text("QuickMeals"),
            Image(image: AssetImage('assets/edamam_logo.png'))
          ]),
        ),
        body: Container(
            margin: EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("Breakfast"),
                _buildRecipe(_getRecipe("breakfast")),
                Text("Lunch"),
                _buildRecipe(_getRecipe("lunch")),
                Text("Dinner"),
                _buildRecipe(_getRecipe("dinner")),
              ],
            )));
  }

  _buildRecipe(recipe) {
    if (recipe == null) {
      return Expanded(
          child: Container(
              alignment: Alignment.center, child: CircularProgressIndicator()));
    }
    return Expanded(
        flex: 1,
        child: Dismissible(
            key: Key(recipe.title),
            onDismissed: (dir) {
              setState(() => meals[recipe.type].removeLast());
            },
            child: GestureDetector(
                onTap: () async => await canLaunch(recipe.url)
                    ? await launch(recipe.url)
                    : throw 'Could not launch ${recipe.url}',
                child: _recipeCard(recipe))));
  }

  Widget _recipeCard(recipe) {
    return Card(
        child: Row(children: <Widget>[
      Expanded(
          child: Container(
              margin: EdgeInsets.all(2),
              child: Column(children: <Widget>[
                Flexible(
                    flex: 1,
                    child: Text(
                      recipe.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    )),
                Spacer(flex: 1),
                Flexible(flex: 1, child: Text("Serves ${recipe.servings}")),
                Flexible(flex: 1, child: Text("${recipe.cal} Calories")),
              ]))),
      Expanded(
          child: Container(
              margin: EdgeInsets.all(2),
              child: FadeInImage.memoryNetwork(
                  placeholder: kTransparentImage, image: recipe.img))),
    ]));
  }
}

class Recipe {
  var type, title, url, img, servings, cal, labels;

  Recipe.fromJson(this.type, Map<String, dynamic> json)
      : url = json["url"],
        title = json["label"],
        img = json["image"],
        servings = json["yield"].round(),
        cal = json["calories"].round(),
        labels = json["dietLabels"] + json["healthLabels"];
}
