import 'package:flutter/material.dart';
import 'dart:async';

enum GridDemoTileStyle { imageOnly, oneLine, twoLine }

typedef BannerTapCallback = void Function(Animal animal);

const double _kMinFlingVelocity = 800.0;

class Animal {
  String assetName;
  String name;
  String color;
  String species;
  int age;
  bool isFavorite = false;

  Animal(this.assetName, this.name, this.species, this.isFavorite);
}

class GridAnimalViewer extends StatefulWidget {
  const GridAnimalViewer({Key key, this.animal}) : super(key: key);

  final Animal animal;

  @override
  _GridAnimalViewerState createState() => _GridAnimalViewerState();
}

class _GridTitleText extends StatelessWidget {
  const _GridTitleText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(text),
    );
  }
}

class _GridAnimalViewerState extends State<GridAnimalViewer>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<Offset> _flingAnimation;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  Offset _normalizedOffset;
  double _previousScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addListener(_handleFlingAnimation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // The maximum offset value is 0,0. If the size of this renderer's box is w,h
  // then the minimum offset value is w - _scale * w, h - _scale * h.
  Offset _clampOffset(Offset offset) {
    final Size size = context.size;
    final Offset minOffset = Offset(size.width, size.height) * (1.0 - _scale);
    return Offset(
        offset.dx.clamp(minOffset.dx, 0.0), offset.dy.clamp(minOffset.dy, 0.0));
  }

  void _handleFlingAnimation() {
    setState(() {
      _offset = _flingAnimation.value;
    });
  }

  void _handleOnScaleStart(ScaleStartDetails details) {
    setState(() {
      _previousScale = _scale;
      _normalizedOffset = (details.focalPoint - _offset) / _scale;
      // The fling animation stops if an input gesture starts.
      _controller.stop();
    });
  }

  void _handleOnScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_previousScale * details.scale).clamp(1.0, 4.0);
      // Ensure that image location under the focal point stays in the same place despite scaling.
      _offset = _clampOffset(details.focalPoint - _normalizedOffset * _scale);
    });
  }

  void _handleOnScaleEnd(ScaleEndDetails details) {
    final double magnitude = details.velocity.pixelsPerSecond.distance;
    if (magnitude < _kMinFlingVelocity) return;
    final Offset direction = details.velocity.pixelsPerSecond / magnitude;
    final double distance = (Offset.zero & context.size).shortestSide;
    _flingAnimation = _controller.drive(Tween<Offset>(
        begin: _offset, end: _clampOffset(_offset + direction * distance)));
    _controller
      ..value = 0.0
      ..fling(velocity: magnitude / 1000.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: _handleOnScaleStart,
      onScaleUpdate: _handleOnScaleUpdate,
      onScaleEnd: _handleOnScaleEnd,
      child: ClipRect(
        child: Transform(
          transform: Matrix4.identity()
            ..translate(_offset.dx, _offset.dy)
            ..scale(_scale),
          child: Image.asset(
            widget.animal.assetName,
//            package: widget.photo.assetPackage,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class GridDemoPhotoItem extends StatelessWidget {
  GridDemoPhotoItem(
      {Key key,
      @required this.animal,
      @required this.tileStyle,
      @required this.onBannerTap})
      : assert(animal != null),
        assert(tileStyle != null),
        assert(onBannerTap != null),
        super(key: key);

  final Animal animal;
  final GridDemoTileStyle tileStyle;
  final BannerTapCallback
      onBannerTap; // User taps on the photo's header or footer.

  void showPhoto(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute<void>(builder: (BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text(animal.name)),
        body: SizedBox.expand(
          child: Hero(
            child: GridAnimalViewer(animal: animal),
            tag: animal.name,
          ),
        ),
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    final Widget image = GestureDetector(
        onTap: () {
          showPhoto(context);
        },
        child: Hero(
            key: Key(animal.name),
            tag: animal.name,
            child: Image.asset(
              animal.assetName,
//              package: photo.assetPackage,
              fit: BoxFit.cover,
            )));

    final IconData icon = animal.isFavorite ? Icons.star : Icons.star_border;

    switch (tileStyle) {
      case GridDemoTileStyle.imageOnly:
        return image;

      case GridDemoTileStyle.oneLine:
        return GridTile(
          header: GestureDetector(
            onTap: () {
              onBannerTap(animal);
            },
            child: GridTileBar(
              title: _GridTitleText(animal.name),
              backgroundColor: Colors.black45,
              leading: Icon(
                icon,
                color: Colors.white,
              ),
            ),
          ),
          child: image,
        );

      case GridDemoTileStyle.twoLine:
        return GridTile(
          footer: GestureDetector(
            onTap: () {
              onBannerTap(animal);
            },
            child: GridTileBar(
              backgroundColor: Colors.black45,
              title: _GridTitleText(animal.name),
              subtitle: _GridTitleText(animal.species),
              trailing: Icon(
                icon,
                color: Colors.white,
              ),
            ),
          ),
          child: image,
        );
    }
    assert(tileStyle != null);
    return null;
  }
}

class GridListDemo extends StatefulWidget {
  const GridListDemo({Key key}) : super(key: key);

  static const String routeName = '/material/grid-list';

  @override
  GridListDemoState createState() => GridListDemoState();
}

class GridListDemoState extends State<GridListDemo> {
  GridDemoTileStyle _tileStyle = GridDemoTileStyle.twoLine;

  List<Animal> animals = <Animal>[
    Animal('images/doberman.jpg', 'Jhon', 'Doberman', true),
    Animal('images/birman.jpg', 'Mestan', 'Birman', true),
    Animal('images/chinchilla.jpg', 'Garfield', 'Chinchilla', true),
    Animal('images/vancat.jpg', 'Pırta', 'Van Kedisi', true),
    Animal('images/Pitbull.jpg', 'Hero', 'Pitbull', true),
    Animal('images/kanis.jpg', 'Jesika', 'Kaniş', true),
    Animal('images/beagle.jpg', 'Bruto', 'Beagle', true),
    Animal('images/snowshoe.jpg', 'Mia', 'Snowshoe', true)
  ];

  void changeTileStyle(GridDemoTileStyle value) {
    setState(() {
      _tileStyle = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pets List'),
        actions: <Widget>[
          PopupMenuButton<GridDemoTileStyle>(
            onSelected: changeTileStyle,
            itemBuilder: (BuildContext context) =>
                <PopupMenuItem<GridDemoTileStyle>>[
                  const PopupMenuItem<GridDemoTileStyle>(
                    value: GridDemoTileStyle.imageOnly,
                    child: Text('Image only'),
                  ),
                  const PopupMenuItem<GridDemoTileStyle>(
                    value: GridDemoTileStyle.oneLine,
                    child: Text('One line'),
                  ),
                  const PopupMenuItem<GridDemoTileStyle>(
                    value: GridDemoTileStyle.twoLine,
                    child: Text('Two line'),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SafeArea(
              top: false,
              bottom: false,
              child: GridView.count(
                crossAxisCount: (orientation == Orientation.portrait) ? 2 : 3,
                mainAxisSpacing: 4.0,
                crossAxisSpacing: 4.0,
                padding: const EdgeInsets.all(4.0),
                childAspectRatio:
                    (orientation == Orientation.portrait) ? 1.0 : 1.3,
                children: animals.map<Widget>((Animal animal) {
                  return GridDemoPhotoItem(
                      animal: animal,
                      tileStyle: _tileStyle,
                      onBannerTap: (Animal animal) {
                        setState(() {
                          animal.isFavorite = !animal.isFavorite;
                        });
                      });
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
