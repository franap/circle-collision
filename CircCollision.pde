long deltaTime;
long prevTime;

CircSpace space = new CircSpace();
long timeElapsed;
int fps, prevFPS;

float acc = .02f;

void setup() {
  size(720, 450);
  prevTime = millis();
  fps = 0;
  prevFPS = 0;
  timeElapsed = 0;
  for(int i=0;i<50;i++) space.circs.add(new Circle());
  try {
    //Thread.sleep(15000);
  } catch(Exception e) {}
}

String getFrameStr() {
  String frCt = frameCount + "";
  String str = "";
  for(int i=4;i>frCt.length();i--)
    str += "0";
  return str + frCt;
}

void draw() {
  deltaTime = millis() - prevTime;
  prevTime = millis();
  space.update();
  for(Circle c: space.circs) {
    c.ph.speed.y += acc;
  }
  
  timeElapsed += deltaTime;
  if(timeElapsed>=1000) {
    timeElapsed = timeElapsed%1000;
    prevFPS = fps;
    fps = timeElapsed>0?1:0;
  } else fps ++;
  
  background(201);
  fill(255);
  int count = 0;
  int totCount = 0;
  for(Circle c: space.circs) {
    if(c.render()) count ++;
    else totCount++;
  }
  fill(0);
  text((prevFPS)+" FPS", 10, 30);
  //text(count+" errors", 10, 60);
  //text(totCount+" circles", 10, 90);
  //if(frameCount<2000) save("frames/" + getFrameStr() + ".png");
  //else exit();
}