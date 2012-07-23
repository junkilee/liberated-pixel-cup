class Avatar extends GameObject {
  //Animation animation;
  int currentAnimation = Animation.WALK;
  int currentOrientation = 0;
  //0 - forward,1 - left, 2 - down, 3 - right
  num currentFrame = 0;
  Vec2 velocity;
  bool _attacking = false;
  Vec2 attackDirection;
  int attackTime = 12;
  int currentAttackTime = 0;
  int health = 100;
  bool alive = true;
  num attackRadius = 32;
  void set attacking(bool b){
    _attacking = b;
    currentAnimation = b ? Animation.SLASH : Animation.WALK;
  }
  bool get attacking() => _attacking;
  Animation animation;
  Avatar(properties):super(properties,0,0){
    velocity = new Vec2(0,0);
    this.tags.add("avatar");
    addTag(this,"avatar");
  }
  void hurt(int damage){
    health -= damage;
    if (alive && health <= 0){
      currentFrame = 0;
      currentAnimation = Animation.DEATH;
      currentOrientation = 0;
      alive = false;
      for (int i = this.tags.length-1;i>=0;i--){
        String tag = this.tags[i];
        if (removalOnDeath.containsKey(tag) && removalOnDeath[tag]){
          this.tags.removeRange(i, 1);
          for (int u = tagMap[tag].length-1;u>=0;u--){
            if (tagMap[tag][u] == this){
              tagMap[tag].removeRange(u,1);
              break;
            }
          }
        }
      }
    }
  }
  void render(html.CanvasRenderingContext2D c){
    c.save();
    c.translate(x,y);
    debugRender(c);
    animation.render(c,currentAnimation,currentOrientation,(currentFrame/5).toInt());
    //Draw Health Bar
    //OPTIMIZE
    final num healthBarSize = 50.0;
    c.fillStyle = "#f00";
    c.fillRect(-healthBarSize/2, -25, healthBarSize, 5);
    c.fillStyle = "#0f0";
    c.fillRect(-healthBarSize/2, -25, health / 100.0 * healthBarSize, 5);
    c.restore();
  }
  void fireTagEvent(String event){
    this.tags.forEach((tag){
      if (tagEvents.containsKey(tag) && tagEvents[tag].containsKey(event)){
        tagEvents[tag][event](this);
      }
    });
  }
}