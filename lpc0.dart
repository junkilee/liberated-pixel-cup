
// Big Island video game source code file
// Copyright (C) 2012  Severin Ibarluzea
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import('dart:html',prefix:"html");
#import('dart:json');

#source("web.dart");
#source("res.dart");

#source("MainMenu.dart");

#source("PathNode.dart");
#source("Path.dart");
#source("GameObject.dart");
#source("FloatingText.dart");
#source("Arrow.dart");
#source("SpawnPoint.dart");
#source("Avatar.dart");
#source("Item.dart");

#source("HiddenCanvas.dart");
#source("Vec2.dart");
#source("Camera.dart");
#source("UIManager.dart");

#source("Color.dart");

#source("TileManager.dart");
#source("OverlayManager.dart");
#source("MenuButton.dart");
#source("MenuInterface.dart");
#source("World.dart");

#source("FrameMap.dart");
#source("Animation.dart");

#source("Notification.dart");

#source("AudioManager.dart");

#resource('main.css');

final int GRAPHIC_BLOCK_SIZE = 32;
final int CHUNK_SIZE = 8;
final int CHUNK_JOIN = 10;

bool DEBUG = false;//TODO make final
final bool MOBILE = false;

int patch_size;

num niceFactor;

html.ImageElement BLANK_IMAGE;

final Map binaryHexMap = const{
  "0":const[0,0,0,0],"1":const[0,0,0,1],"2":const[0,0,1,0],"3":const[0,0,1,1],
  "4":const[0,1,0,0],"5":const[0,1,0,1],"6":const[0,1,1,0],"7":const[0,1,1,1],
  "8":const[1,0,0,0],"9":const[1,0,0,1],"a":const[1,0,1,0],"b":const[1,0,1,1],
  "c":const[1,1,0,0],"d":const[1,1,0,1],"e":const[1,1,1,0],"f":const[1,1,1,1]
};

final List<String> friendlySpeech = const[
   "Hi!",
   "Hiya!",
   "Hello!",
   "It's not so scary with you around!",
   "Thanks for the help!"
];
final List<String> lostSpeech = const[
                                      "Help!",
                                      "Where is everyone?",
                                      "Where do I go?",
                                      "Please help me!",
                                      "Where am I?"
                                      ];
final List<String> meanSpeech = const[
                                          "Why don't you just go?",
                                          "Get outta here!",
                                          "Get out!",
                                          "Why won't you help us?",
                                          "It's outsiders like you that caused this!"
                                       ];
final List<String> foundSpeech = const[
                                      "Can you take me somewhere safe?",
                                      "Please help me!",
                                      "Please take me home!"
                                   ];
final List<String> scaredSpeech = const[
                                       "Ahhhh!",
                                       "Look out!",
                                       "Run!",
                                       "AHHHH!",
                                       "Woah!"
                                    ];

Map<String,Map<String,Function>> tagEvents;

Map<String,bool> removalOnDeath = const{
  "wander":true,
  "nice":true,
  "hostile":true,
  "hostile-wander":true,
  "mean":true,
  "scared":true,
  "citizen":true
};

Map<String,List<GameObject>> tags; //These are the same thing (dirty work around)
Map<String,List<GameObject>> tagMap;// <<<<<
Map<String,Object> classMap;
Map<String,Animation> animationMap;

Dynamic addTag(GameObject object,String tag) => tags[tag] == null ? tags[tag] = new List<GameObject>.from([object]) : tags[tag].add(object);
void rmTag(GameObject object,String tag) {
  int index = tags[tag].indexOf(object);
  if (index!=-1){
    tags[tag].removeRange(index,1);
  }
}

int SCREEN_WIDTH;
int SCREEN_HEIGHT;
final int STATIC_WIDTH = 800;
final int STATIC_HEIGHT = 800;
int RENDER_DISTANCE;

num RESOLUTION = 1;

UIManager event;
AudioManager audio;

List<Notification> notifications;

World world;

void GameOver(html.CanvasRenderingContext2D c){
  world.paused = true;
  Vec2 menu_pos = new Vec2(SCREEN_WIDTH,0);
  html.ImageElement img = new html.ImageElement();
  img.src = game.canvas.toDataURL('image/png');
  game = null;
  int timePass = 0;
  bool rcycle(int a){
    timePass ++;
    c.globalAlpha = 1;
      //world.render(c);
     c.drawImage(img, 0, 0);
    c.save();
    menu_pos.x -= (menu_pos.x - (SCREEN_WIDTH - 400))/10;
    c.translate(menu_pos.x,menu_pos.y);
    //Okay, draw all menu items
    c.fillStyle = "#000";
    c.globalAlpha = .75;
    c.fillRect(0,0,400,SCREEN_HEIGHT);
    
    //GAME OVER
    c.globalAlpha = 1;
    c.font = "48px Arial";
    c.fillStyle = "#fff";
    c.fillText("Game Over",75,75);
    
    //Stats
    c.font = "18px Arial";
    num ypos = 160;
    [
     ["Village Population","${world.totalPopulation}"],
     ["Zombie Population","${world.zombie_max}"],
     ["Zombies Killed","${world.zombies_killed}"],
     ["Villagers Saved","${world.saved}"],
     ["Days Survived","${world.dayCount}"],
    ].forEach((List<String> not){
      c.textAlign = "left";
      c.fillText(not[0],25,ypos);
      c.textAlign = "right";
      c.fillText(not[1],400-50,ypos);
      ypos += 40;
    });
    
    c.textAlign = "center";
    c.fillText("Click anywhere to play again", 200, ypos + 50);
    c.fillText("Game by Severin Ibarluzea", 200, SCREEN_HEIGHT-50);
    c.fillText("For the Liberated Pixel Cup (2012)", 200, SCREEN_HEIGHT-25);
    
    c.restore();
    if (game == null){
    html.window.requestAnimationFrame(rcycle);
    }
  }
  html.window.requestAnimationFrame(rcycle);
  event.onClick.add((e){
    if (timePass >= 120){
      print("Starting New Game");
      main();
      return true;
    }
  });
}

void renderNotifications(html.CanvasRenderingContext2D c){
  for (int i = notifications.length-1;i>=0;i--){
    if (notifications[i].render(c)){
      notifications.removeRange(i,1);
    }
  }
}
void notify(String text){
  notifications.forEach((Notification note){
    note.y += Notification.HEIGHT;
  });
  notifications.add(new Notification(text));
}
void switchTag(GameObject o,String oldTag,String newTag){
  o.removeTag(oldTag);
  rmTag(o,oldTag);
  o.tags.add(newTag);
  addTag(o,newTag);
}
int rpatCount = 0;
bool rpat(int n){
  return ((rpatCount ++)%n == 0);
}
Game game;
MainMenu menu;
void main() {
  html.window.on.load.add((e){
   menu = new MainMenu();
  });
}
void startGame(){
  menu = null;
  game = new Game();
}
class Game {
  html.CanvasElement canvas;
  html.CanvasRenderingContext2D context;
  
  Game(){
    niceFactor = 0;
    rpatCount = (Math.random() * 64).toInt();
    classMap = {
        "spawn":(p)=>new SpawnPoint(p),
        "avatar":(p)=>new Avatar(p),
        "node":(p)=>new GameObject(p,0,0),
        "arrow":(p)=>new Arrow(p),
        "floating_text":(p)=>new FloatingText(p)
    };
    tagEvents = {
        "citizen":{
          "init":(Avatar avatar){
            if (avatar.damage == null){
              avatar.armor = 1;
              avatar.damage = 0;
            }
            avatar.speed = .5 + Math.random() * 1.5;
            avatar["destination"] = avatar.clone();//DIRTY FIX
            avatar["waitTime"] = 0;
            num r = Math.random() + niceFactor;
            if (r<.1){
              avatar.tags.add("mean");
              addTag(avatar,"mean");
            }else if (r>1){
              avatar.tags.add("nice");
              addTag(avatar,"nice");
            }
            avatar["followOffset"] = new Vec2(Math.random() * 128 - 64,Math.random() * 128 - 64);
          },
          "update":(Avatar citizen){
            if (!citizen.hasTag("scared")){
              List<Avatar> zoms =  tags["zombie"];
              for (int i = (Math.random() * zoms.length).toInt(),iter = 0;iter<zoms.length / 16;iter++,i++){
                int index = i%zoms.length;
                if (zoms[index].alive && zoms[index].distanceTo(citizen) < 96){
                  ["wander","traveler","lost","following","homebound"].forEach((String tag){
                    if (citizen.hasTag(tag)){
                      citizen.removeTag(tag);
                      rmTag(citizen,tag);
                    }
                  });
                  citizen.say(scaredSpeech[(scaredSpeech.length * Math.random()).toInt()],100);
                  citizen.tags.add("scared");
                  addTag(citizen,"scared");
                  citizen["scaredOf"] = zoms[index];
                  tagEvents["scared"]["init"](citizen);
                  return;
                  
                }
              }
              //Basically the exact same thing with corpses
              zoms = tags["corpse"];
              for (int i = (Math.random() * zoms.length).toInt(),iter = 0;iter<zoms.length / 16;iter++,i++){
                int index = i%zoms.length;
                if (!zoms[index].hasTag("zombie") && zoms[index].distanceTo(citizen) < 96){
                  ["wander","traveler","lost","following","homebound"].forEach((String tag){
                    if (citizen.hasTag(tag)){
                      citizen.removeTag(tag);
                      rmTag(citizen,tag);
                    }
                  });
                  citizen.say(scaredSpeech[(scaredSpeech.length * Math.random()).toInt()]);
                  citizen.tags.add("scared");
                  addTag(citizen,"scared");
                  citizen["scaredOf"] = zoms[index];
                  tagEvents["scared"]["init"](citizen);
                  return;
                  
                }
              }
            }
          },
          "hit":(Avatar citizen){
            if (citizen.distanceTo(world.player) < 256){
              audio.play("hurt");
            }
            if (world.player.attacking){
              niceFactor -= .005;
              ["wander","traveler","lost","following","homebound","scared"].forEach((String tag){
                if (citizen.hasTag(tag)){
                  citizen.removeTag(tag);
                  rmTag(citizen,tag);
                }
              });
              citizen.say(scaredSpeech[(scaredSpeech.length * Math.random()).toInt()]);
              citizen.tags.add("scared");
              addTag(citizen,"scared");
              citizen["scaredOf"] = world.player;
              tagEvents["scared"]["init"](citizen);
            }
          },
          "die":(Avatar avatar){
            world.totalPopulation --;
            world.awakePopulation --;
            world.zombie_max ++;
            niceFactor -= .01;
            if (world.player.attacking && world.player.distanceTo(avatar)<256){
              niceFactor -= .05;
              world.giveCoin(avatar,(10 * Math.random() + 2).toInt());
            }
          },
          "collide":(Avatar citizen){
            if (rpat(120)){
              citizen.add(citizen.velocity);
            }
          }
        },
        "player":{
          "init":(Avatar player){
            player.damage = 25;
            player.armor = .5;
            player.speed = 1;
          },
          "die":(Avatar player){
            notify("You have died, please wait");
            player["deadTime"] = 540;
          },
          "decomposed":(Avatar player){
            GameOver(context); 
          },
          "update":(Avatar player){
            player.health = (player.health < world.player_max_health) ? player.health + .2 : world.player_max_health;
            if (world.collisionAtVec2(player)){
              player.add(player.velocity);
            }
          }
        },
        "scared":{
          "init":(Avatar citizen){
            citizen["runDirection"] = citizen.clone().sub(citizen["scaredOf"]).normalize().multiplyScalar(citizen.speed);
          },
          "update":(Avatar citizen){
            citizen.velocity.add(citizen["runDirection"]);
            if (rpat(8)){
              Avatar zom = citizen["scaredOf"];
              if (zom.distanceTo(citizen) > world.AGRO_DISTANCE + 32){
                switchTag(citizen,"scared","lost");
                citizen.tags.add("wander");
                addTag(citizen,"wander");
              }
            }
          }
        },
        "traveler":{
          "init":(Avatar a){
            List<PathNode> cnodes = world.getClosePathNodes(a);
            if (cnodes.length > 0){
              int ni;
              if (world.time < 16){
                ni = (cnodes.length * Math.random()).toInt();
                a["path"] = cnodes[ni].path;
                a["pathDirection"] = cnodes[ni].start ? 1 : -1;
                a["pathIndex"] = cnodes[ni].start ? 0 : cnodes[ni].path.points.length - 1;
                a["pathPoint"] = cnodes[ni].clone();
                a["pathMove"] = cnodes[ni].clone().sub(a).normalize().multiplyScalar(a.speed);
              }else{
                for (int i = cnodes.length-1;i>=0;i--){
                  if (cnodes[i].house){
                    tags["house"].some((GameObject house){
                      if (house.distanceTo(a) < 256){
                        a["home"] = house;
                        return true;
                      }
                      return false;
                    });
                    switchTag(a,"traveler","homebound");
                    tagEvents["homebound"]["init"](a);
                    return;
                  }
                }
                switchTag(a,"traveler","wander");
                tagEvents["wander"]["init"](a);
                return;
              }
            }else{
              switchTag(a,"traveler","wander");
              tagEvents["wander"]["init"](a);
            }
          },
          "collide":(Avatar a){
            a["pathPoint"] = a["path"].points[a["pathIndex"]];
            a["pathMove"] = a["pathPoint"].clone().sub(a).normalize().multiplyScalar(a.speed);
            a.add(a["pathMove"]);
          },
          "update":(Avatar a){
            a.velocity.add(a["pathMove"]);
            if (a["pathPoint"].distanceTo(a) < 32){
              a["pathIndex"] += a["pathDirection"];
              if (a["pathIndex"] < 0 || a["pathIndex"] >= a["path"].points.length){
                tagEvents["traveler"]["init"](a);
              }else{
                a["pathPoint"] = a["path"].points[a["pathIndex"]].clone();
                num d = a.distanceTo(a["pathPoint"])/4;
                a["pathPoint"].addTo(Math.random() * d - d/2,Math.random() * d - d/2);
                a["pathMove"] = a["pathPoint"].clone().sub(a).normalize().multiplyScalar(a.speed);
              }
            }
          }
        },
        "homebound":{
          "init":(Avatar avatar){
            avatar["collisionCount"] = 0;
            //TODO SIMPLIFY
            GameObject home = avatar["home"];
            avatar["homeboundDirection"] = home.clone().sub(avatar).normalize().multiplyScalar(avatar.speed);
          },
          "update":(Avatar avatar){
            avatar.velocity.add(avatar["homeboundDirection"]);
            if (rpat(8)){
              num d = avatar["home"].distanceTo(avatar);
              if (d>256){
                bool found = false;
                tags["house"].some((GameObject house){
                  if (house.distanceTo(avatar)<256){
                    avatar["home"] = house;
                    found = true;
                    return true;
                  }
                  return false;
                });
                if (found){
                  avatar["collisionCount"] = 0;
                  avatar["homeboundDirection"] = avatar["home"].clone().sub(avatar).normalize().multiplyScalar(avatar.speed);
                }else{
                  switchTag(avatar,"homebound","lost");
                  avatar.tags.add("wander");
                  addTag(avatar,"wander");
                }
              }else if (d<32){
                avatar.markForRemoval();
                world.awakePopulation --;
              }
            }
          },
          "collide":(Avatar avatar){
            avatar["collisionCount"] ++;
            if (avatar["collisionCount"] > 120){
              switchTag(avatar,"homebound","lost");
              avatar.tags.add("wander");
              addTag(avatar,"wander");
            }else if (avatar.distanceTo(avatar["home"])<256){
              avatar.markForRemoval();
              world.awakePopulation --;
            }
            /*if (avatar["home"].distanceTo(avatar)<256){
              avatar.markForRemoval();
              world.awakePopulation --;
            }else{
              tags["house"].some((GameObject house){
                if (house.distanceTo(avatar) < 256){
                  avatar.markForRemoval();
                  world.awakePopulation --;
                  return true;
                }
                return false;
              });
              if (!avatar.markedForRemoval){
                switchTag(avatar,"homebound","lost");
                avatar.tags.add("wander");
                addTag(avatar,"wander");
              }
            }*/
          }
        },
        "lost":{
          "update":(Avatar avatar){
            if (avatar.speaking){
              avatar.sayTime --;
              if (avatar.sayTime < 0){
                avatar.speaking = false;
              }
            }
            if (rpat(8) && avatar.distanceTo(world.player) < 64){
              avatar.say(foundSpeech[(foundSpeech.length * Math.random()).toInt()]);
              switchTag(avatar,"lost","following");
              avatar.removeTag("wander");
              rmTag(avatar,"wander");
            }else{
              for (int i = (Math.random() * tags["house"].length).toInt(),iter = 0;iter<4;iter++,i++){
                int index = i%tags["house"].length;
                if (tags["house"][index].distanceTo(avatar) < 256){
                  avatar["home"] = tags["house"][index];
                  iter = 9999;
                  switchTag(avatar,"lost","homebound");
                  tagEvents["homebound"]["init"](avatar);
                  avatar.removeTag("wander");
                  rmTag(avatar,"wander");
                }
              }
            }
          }
        },
        "corpse":{
          "init":(Avatar avatar){
            avatar["deadTime"] = 0;
            avatar.speaking = false;
          },
          "update":(Avatar avatar){
            avatar["deadTime"] ++;
            if (avatar["deadTime"] > 600){
              avatar.fireTagEvent("decomposed");
              avatar.markForRemoval();
            }
          }
        },
        "following":{
          "update":(Avatar avatar){
            if (avatar.speaking){
              avatar.sayTime --;
              if (avatar.sayTime < 0){
                avatar.speaking = false;
              }
            }
            if (avatar.distanceTo(world.player)>64){
              avatar.velocity.add(world.player.clone().add(avatar["followOffset"]).sub(avatar).normalize().multiplyScalar(2));
            }
            //Check if avatar is near any houses
            for (int i = (Math.random() * tags["house"].length).toInt(),iter = 0;iter<4;iter++,i++){
              int index = i%tags["house"].length;
              if (tags["house"][index].distanceTo(avatar) < 256){
                avatar.say(rpat(2) ? "Thank you!" : "Thanks!",100 );
                avatar["home"] = tags["house"][index];
                world.giveCoin(avatar,(Math.random() * 20 + 5).toInt());
                iter = 9999;
                niceFactor += .05;
                world.saved ++;
                switchTag(avatar,"following","homebound");
                tagEvents["homebound"]["init"](avatar);
              }
            }
          }
        },
        "wander":{
          "collide":(Avatar avatar){
            avatar.prop["destination"] = avatar.clone().addTo(Math.random() * 100 - 50,Math.random() * 100 - 50);
          },
          "init":(Avatar avatar){
            avatar.prop["destination"] = avatar.clone();
            avatar.prop["waitTime"] = 0;
          },
          "update":(Avatar avatar){
            if (avatar.prop["waitTime"] > 0){
              avatar.prop["waitTime"] --;
            }else if (avatar.prop["destination"].distanceTo(avatar)>2){
              Vec2 destination = avatar.prop["destination"];
              avatar.velocity.add(destination.clone().sub(avatar).normalize().multiplyScalar(avatar.speed));
            }else{
              if (Math.random() < .75){
                avatar.prop["destination"] = avatar.clone().addTo(Math.random() * 400 - 200,Math.random() * 400 - 200);
              }else{
                avatar.prop["destination"] = avatar.clone();
                avatar.prop["waitTime"] = Math.random() * 200;
                avatar.currentFrame = 0;
                avatar.velocity.zero();
              }
            }
          }
        },
        "nice":{
          "init":(Avatar avatar){
            avatar.sayTime = Math.random() * 500;
          },
          "update":(Avatar avatar){
            if (avatar.sayTime<0){
              avatar.speaking = false;
              tags["player"].forEach((Avatar player){
                if (player.distanceTo(avatar) < 80){
                  avatar.say(friendlySpeech[(Math.random() * friendlySpeech.length).toInt()]);
                }
              });
              avatar.sayTime = Math.random() * 500;
            }else{
              avatar.sayTime --;
            }
          }
        },
        "mean":{
          "init":(Avatar avatar){
            avatar.sayTime = Math.random() * 500;
          },
          "update":(Avatar avatar){
            if (avatar.sayTime<0){
              avatar.speaking = false;
              tags["player"].forEach((Avatar player){
                if (player.distanceTo(avatar) < 80){
                  avatar.say(meanSpeech[(Math.random() * meanSpeech.length).toInt()]);
                }
              });
              avatar.sayTime = Math.random() * 500;
            }else{
              avatar.sayTime --;
            }
          }
        },
        "salesman":{
          "update":(Avatar avatar){
            if (avatar.sayTime<0){
              avatar.speaking = false;
              if (rpat(2)){
                avatar.say(avatar["calls"][(avatar["calls"].length * Math.random()).toInt()]);
              }
              avatar.sayTime = 100+Math.random() * 200;
            }else{
              avatar.sayTime --;
            }
            if (world.player.distanceTo(avatar) < 128 && notifications.length == 0){
              notify("Press Space to Interact");
            }
          }
        },
        "arrow":{
          "update":(Arrow arrow){
            arrow.add(arrow["direction"].divideScalar(1.5));
            if (world.damageBubble(arrow, 32, arrow["damage"], arrow["direction"].clone().normalize()).length>0 || world.collisionAtVec2(arrow) || arrow.distance++ > 12){
              arrow.remove();
            }
          }
        },
        "zombie":{
          "init":(Avatar zom){
            zom.speed = .5 + Math.random();
          },
          "die":(Avatar a){
            if (world.player.distanceTo(a) < 256 && world.player.attacking){
              world.zombies_killed ++;
              world.giveCoin(a,(Math.random() * 4 + 1).toInt());
            }
          }
        },
        "hostile-wander":{
          "init":(Avatar zom){
            zom["originalPosition"] = zom.clone();
            zom.damage = world.ZOMBIE_DAMAGE;
            zom.armor = world.ZOMBIE_ARMOR;
            tagEvents["wander"]["init"](zom);
          },
          "update":(Avatar zom){
            //Check for nearby enemies
            if (rpat(20)){
              if (zom.prop["waitTime"] > 0){
                zom.prop["waitTime"] --;
              }else if (zom.prop["destination"].distanceTo(zom)>2){
                Vec2 destination = zom.prop["destination"];
                zom.velocity.add(destination.clone().sub(zom).normalize().multiplyScalar(zom.speed * world.ZOMBIE_SPEED));
              }else{
                if (Math.random() < .75){
                  zom.prop["destination"] = zom.clone().addTo(Math.random() * 400 - 200,Math.random() * 400 - 200);
                }else{
                  zom.prop["destination"] = zom.clone();
                  zom.prop["waitTime"] = Math.random() * 200;
                  zom.currentFrame = 0;
                  zom.velocity.zero();
                }
              }
              tags["friendly"].some((Avatar avatar){
                if (avatar.alive && avatar.distanceTo(zom) < world.AGRO_DISTANCE){
                  rmTag(zom,"hostile-wander");
                  zom.removeTag("hostile-wander");
                  addTag(zom,"hostile");
                  zom.tags.add("hostile");
                  zom["target"] = avatar;
                  return true;
                }
                return false;
              });
            }
          },
          "collide":(Avatar zom){
            zom.prop["destination"] = zom.clone().addTo(Math.random() * 100 - 50,Math.random() * 100 - 50);
          },
          "hit":(Avatar zom){
            tags["friendly"].some((Avatar avatar){
              if (avatar.alive && avatar.attacking && avatar.distanceTo(zom) < world.AGRO_DISTANCE*2 ){
                rmTag(zom,"hostile-wander");
                zom.removeTag("hostile-wander");
                addTag(zom,"hostile");
                zom.tags.add("hostile");
                zom["target"] = avatar;
                return true;
              }
              return false;
            });
          }
        },
        "hostile":{
          "update":(Avatar zom){
            if (zom["target"] != null && zom["target"].alive && !zom["target"].markedForRemoval){
              Avatar target = zom["target"];
              num distance = target.distanceTo(zom);
              
              if (distance < 32){
                zom.attacking = true;
                zom.attackDirection = target.clone().sub(zom).normalize();
                zom.velocity.divideScalar(2);
              }else if (distance < world.AGRO_DISTANCE * 2){
                zom.attacking = false;
                zom.velocity.sub(zom.clone().sub(target).normalize().multiplyScalar(world.ZOMBIE_SPEED*zom.speed));
              }else{
                switchTag(zom,"hostile","hostile-wander");
                zom["target"] = null;
              }
            }else{
              switchTag(zom,"hostile","hostile-wander");
            }
          },
          "kill":(Avatar zom){
            if (!zom["target"].alive){
              zom.removeTag("hostile");
              zom.tags.add("hostile-wander");
              addTag(zom,"hostile-wander");
              rmTag(zom,"hostile");
              zom["target"] = null;
              zom.attacking = false;
            }
          },
          "hit":(Avatar zom){
            tags["friendly"].some((Avatar friend){
              if (friend.attacking && friend.distanceTo(zom) < 96){
                zom["target"] = friend;
                return true;
              }
              return false;
            });
          }
        },
        "nestbound":{
          "init":(Avatar zom){
            zom["nestDirection"] = zom["originalPosition"].clone().sub(zom).normalize();
            zom["collisionCount"] = 0;
          },
          "update":(Avatar zom){
            zom.velocity.add(zom["nestDirection"]);
            if (rpat(4) && zom.distanceTo(zom["originalPosition"])<32){
              zom.markForRemoval();
            }
          },
          "collide":(Avatar zom){
            zom["collisionCount"] ++;
            if (zom["collisionCount"] > 120){
              zom.markForRemoval();
            }
          }
        },
        "floating_text":{
          "update":(FloatingText ftext){
            ftext.time++;
            ftext.y -= .5;
            if (ftext.time > 150){
              ftext.remove();
            }
          }
        }
    };
    notifications = new List<Notification>();
    
    BLANK_IMAGE = new html.ImageElement();
    
    tags = {"zombie":new List<Avatar>(),"corpse":new List<Avatar>(),"wander":new List<Avatar>(),"lost":new List<Avatar>()};
    tagMap = tags;
    
    audio = new AudioManager();
    
    animationMap = new Map<String,Animation>();
    canvas = html.document.query("#canvas");
    
    canvas.width  = 800;
    canvas.height = 600;
    //Uncomment for fullscreen
    //canvas.width = (html.window.innerWidth/RESOLUTION).toInt();
    //canvas.height = (html.window.innerHeight/RESOLUTION).toInt();
    context = canvas.getContext("2d");
    SCREEN_WIDTH = canvas.width;
    SCREEN_HEIGHT = canvas.height;
    event = new UIManager();
    RENDER_DISTANCE = ((SCREEN_WIDTH + SCREEN_HEIGHT)*2/4).toInt();
    world = new World();
    print("Loading World");
    web.load("game.json",(data){
      world.load(data,(){
        loadFinish();
      });
    });
  }
  void loadFinish(){
    //Normally we increment a global load variable until all components loaded
    //TODO but there's only one
    //world.render(context);
    world.startCycle(context);
  }
}
