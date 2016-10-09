class CircSpace {
  ArrayList<Circle> circs = new ArrayList();
  
  boolean updateSpeed(Circle c, Circle obs) {
    float tmp;
    if((tmp=c.pos.dist(obs.pos))<(c.rad+obs.rad-EPSILON)) {
      PVector trans = new PVector(c.pos.x, c.pos.y);
      trans.sub(obs.pos);
      trans.normalize();
      trans.mult(tmp-c.rad-obs.rad);
      obs.pos.add(trans);
    }
    float x = c.pos.x - obs.pos.x;
    float y = c.pos.y - obs.pos.y;
    float spX = c.ph.translation.x - obs.ph.translation.x;
    float spY = c.ph.translation.y - obs.ph.translation.y;
    float spMagSq = spX*spX + spY*spY;
    if(spMagSq<EPSILON) return false;
    
    float r = obs.rad + c.rad;
    
    float unk;
    float unkSq = -(spX*y - x*spY)*(spX*y - x*spY) + r*r*spMagSq;
    if(unkSq<0) {
      if(unkSq<-EPSILON) return false;
      else unk = 0;
    } else unk = sqrt(unkSq);
    
    float t1 = - (x*spX + y*spY + unk);
    float t2 = - x*spX - y*spY + unk;
    float t = min(t1, t2);
    //if(t<0) t = max(t1, t2);
    if(t<-EPSILON || t>spMagSq) t = spMagSq;
    else if(t<EPSILON || Float.isNaN(t)) t = 0;
    
    c.ph.timeLost = deltaTime - t*(deltaTime-c.ph.timeLost)/spMagSq;
    obs.ph.timeLost = deltaTime - t*(deltaTime-obs.ph.timeLost)/spMagSq;
    
    c.ph.translation.x = c.ph.translation.x*t/spMagSq;
    c.ph.translation.y = c.ph.translation.y*t/spMagSq;
    obs.ph.translation.x = obs.ph.translation.x*t/spMagSq;
    obs.ph.translation.y = obs.ph.translation.y*t/spMagSq;
    
    //Change speed direction
    float sumSp = c.ph.speed.mag() + obs.ph.speed.mag();
    float sumW = c.ph.weight + obs.ph.weight;
    c.ph.newSpeed.x = (c.pos.x+c.ph.translation.x - obs.pos.x); 
    c.ph.newSpeed.y = (c.pos.y+c.ph.translation.y - obs.pos.y);
    obs.ph.newSpeed.set(-c.ph.newSpeed.x, -c.ph.newSpeed.y);
    c.ph.newSpeed.normalize();
    c.ph.newSpeed.mult(obs.ph.weight*sumSp/sumW*c.ph.e);
    obs.ph.newSpeed.normalize();
    obs.ph.newSpeed.mult(c.ph.weight*sumSp/sumW*obs.ph.e);
    return true;
  }
  
  boolean willCollide(Circle c1, Circle c2) {
    float spX = c1.ph.translation.x - c2.ph.translation.x;
    float spY = c1.ph.translation.y - c2.ph.translation.y;
    float radSum = c1.rad + c2.rad + EPSILON;
    float spMagSq = spX*spX + spY*spY;
    if(spMagSq<EPSILON) return dist(c1.pos.x, c1.pos.y, c2.pos.x, c2.pos.y)<radSum;
    
    float t = spX*(c2.pos.x - c1.pos.x) + spY*(c2.pos.y - c1.pos.y);
    if(t<0)
      return dist(c1.pos.x, c1.pos.y, c2.pos.x, c2.pos.y)<radSum;
    else if(t>spMagSq)
      return dist(c1.pos.x + spX, c1.pos.y + spY, c2.pos.x, c2.pos.y)<radSum;
    else
      return dist(c1.pos.x + t*spX/spMagSq, c1.pos.y + t*spY/spMagSq, c2.pos.x, c2.pos.y)<radSum;
  }
  
  void update() {
    ArrayList<Circle> cause = new ArrayList();
    ArrayList<Circle> effect = new ArrayList();
    for(int i=0;i<circs.size();i++) {
      Circle a = circs.get(i);
      a.ph.translation.x = a.ph.speed.x*deltaTime;
      a.ph.translation.y = a.ph.speed.y*deltaTime;
      /*float newX = a.pos.x+a.ph.translation.x;
      float newY = a.pos.y+a.ph.translation.y;
      if(newX<a.rad) a.ph.translation.x = a.rad-a.pos.x;
      else if(newX>width-a.rad) a.ph.translation.x = width-a.rad-a.pos.x;
      if(newY<a.rad) a.ph.translation.y = a.rad-a.pos.y;
      else if(newY>height-a.rad) a.ph.translation.y = height-a.rad-a.pos.y;*/
      a.ph.timeLost = 0;
      a.ph.newSpeed.set(a.ph.speed.x, a.ph.speed.y);
    }
    for(int i=0;i<circs.size();i++) {
      Circle a = circs.get(i);
      for(int j=i+1;j<circs.size();j++) {
        Circle b = circs.get(j);
        //if(((a.pos.x-b.pos.x)*(a.pos.x-b.pos.x) + (a.pos.y-b.pos.y)*(a.pos.y-b.pos.y))<(a.rad+b.rad)*(a.rad+b.rad)) {
        if(willCollide(a, b)) {
          if(!updateSpeed(a, b)) continue;
          Circle newCause = b;
          Circle newEffect = a;
          ArrayList<Circle[]> toUpdate = new ArrayList();
          toUpdate.add(new Circle[]{newCause, newEffect});
          while(!toUpdate.isEmpty()) {
            updateSpeed(toUpdate.get(0)[1], toUpdate.get(0)[0]);
            for(int x=0;x<cause.size();x++) {
              if(cause.get(x)==toUpdate.get(0)[0]) {
                Circle needsUpdate = effect.get(x);
                needsUpdate.ph.translation.x = needsUpdate.ph.speed.x*deltaTime;
                needsUpdate.ph.translation.y = needsUpdate.ph.speed.y*deltaTime;
                needsUpdate.ph.timeLost = 0;
                needsUpdate.ph.newSpeed.set(needsUpdate.ph.speed.x, needsUpdate.ph.speed.y);
                toUpdate.add(new Circle[]{needsUpdate, toUpdate.get(0)[0]});
              }
            }
            toUpdate.remove(0);
          }
          cause.add(b);
          effect.add(a);
        }
      }
    }
    for(Circle c: circs) {
      c.ph.speed.set(c.ph.newSpeed.x, c.ph.newSpeed.y);
      float newX, newY;
      newX = c.pos.x + c.ph.translation.x;
      newY = c.pos.y + c.ph.translation.y;
      if(Float.isNaN(newX) || Float.isNaN(newY)) {
        c.ph.translation.set(0, 0);
        c.ph.timeLost = 0;
        continue;
      }
      boolean dominoEffect = false;
      if(newX<=c.rad) {
        newX=c.rad;
        c.ph.speed.x = -c.ph.speed.x;
        dominoEffect = true;
      } else if(newX>=(width-c.rad)) {
        newX=width-c.rad;
        c.ph.speed.x = -c.ph.speed.x;
        dominoEffect = true;
      }
      if(newY<c.rad) {
        newY=c.rad;
        c.ph.speed.y = -c.ph.speed.y;
        dominoEffect = true;
      } else if(newY>=(height-c.rad)) {
        newY=height-c.rad;
        c.ph.speed.y = -c.ph.speed.y;
        dominoEffect = true;
      }
      c.pos.x = newX;
      c.pos.y = newY;
      c.ph.translation.set(0, 0);
      c.ph.timeLost = 0;
      if(dominoEffect) {
        ArrayList<Circle[]> toUpdate = new ArrayList();
        toUpdate.add(new Circle[]{c, null});
        while(!toUpdate.isEmpty()) {
          if(toUpdate.get(0)[1]!=null)
            updateSpeed(toUpdate.get(0)[1], toUpdate.get(0)[0]);
          for(int x=0;x<cause.size();x++) {
            if(cause.get(x)==toUpdate.get(0)[0]) {
              Circle needsUpdate = effect.get(x);
              needsUpdate.ph.translation.x = needsUpdate.ph.speed.x*deltaTime;
              needsUpdate.ph.translation.y = needsUpdate.ph.speed.y*deltaTime;
              needsUpdate.ph.timeLost = 0;
              needsUpdate.ph.newSpeed.set(needsUpdate.ph.speed.x, needsUpdate.ph.speed.y);
              toUpdate.add(new Circle[]{needsUpdate, toUpdate.get(0)[0]});
            }
          }
          toUpdate.remove(0);
        }//End while
      } //End domino effect
    }
  }
  
}

int cc = 0;

class Circle {
  PhysicProps ph;
  float rad;
  PVector pos;
  
  Circle() {
    rad = random(10, 25);
    pos = new PVector();
    pos.x = random(30, width-30);
    pos.y = random(30, height-30);
    ph = new PhysicProps();
    //ph.speed = new PVector(0.1*(random(0, 1)==0?-1:1), 0.1*(random(0, 1)==0?-1:1));
    ph.speed = new PVector(.1f*(cc%2==0?-1:1), -.1f);
    cc ++;
    ph.translation = new PVector();
    ph.newSpeed = new PVector();
    ph.weight = PI*rad*rad;
    ph.e = random(985, 999)/1000.f;
    //ph.e = 1.f;
  }
  
  boolean render() {
    ellipse(pos.x, pos.y, rad*2, rad*2);
    return Float.isNaN(pos.x)||Float.isNaN(pos.y);
  }
}
