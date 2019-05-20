import controlP5.*;
import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.utils.*; 
import de.fhpotsdam.unfolding.marker.*;
import de.fhpotsdam.unfolding.providers.OpenStreetMap.*;
import de.fhpotsdam.unfolding.providers.Microsoft.*;

UnfoldingMap map;
//SimplePointMarker gpMarker;
Minim minim;
//AudioPlayer player1;
//AudioPlayer player2;
audControl acp;
legBar lb;
String file;
int activebutton = 1;
int idTicker = 0;
button[] buttons = new button[10];
int presBut = 0;
int presLeg = 0;
int presNode = 0;
int acpWidth = 300;
int legInterStart = 390;
int legBarWidth = 350;
int lowerInterfaceYPos = 680;
int audPosMillis;

void setup() {
  size(1366, 740);
  map = new UnfoldingMap(this, new AerialProvider());
  minim = new Minim(this);
  MapUtils.createDefaultEventDispatcher(this, map);
  map.zoomAndPanTo(new Location(52f, 0f), 4);
  buttons[0] = new button(1290, 20,0);
  ControlP5 cp5 = new ControlP5(this);
  acp = new audControl(50,lowerInterfaceYPos,0, minim, cp5);
  lb = new legBar();
}

void draw() {
  map.draw();
  lb.display();
  for (int i=0; i < activebutton; i++) {
    if (buttons[i].hasfile) {
      if (buttons[i].walk.fileready) {
        buttons[i].walk.drawDataSet();
      }else{
        buttons[i].walk.refresh();
        buttons[i].walk.mouseOverCheck(mouseX, mouseY);
      }
    }
    buttons[i].mouseOverCheck(mouseX, mouseY);
    buttons[i].display();
      
  }
  
  acp.display();
  acp.mouseOverCheck(mouseX, mouseY);
//  if (key == ' '){
    //println("space pressed");
//    key = 'a';
//  }
}

void mouseClicked() {
  for (int i=0; i < activebutton; i++) {
    if (buttons[i].mouseOverCheck(mouseX, mouseY)) {
      if (mouseButton == LEFT) {
        if (buttons[i].hasfile == false) {
          buttons[i].getFile();
        } else if (buttons[i].walk.hidden) {
          buttons[i].showWalk();
        } else {
          buttons[i].hideWalk();
        }
      } else if (buttons[i].hasfile) {
        buttons[i].deleteDataset();
      }
    }
    
    if (buttons[i].hasfile){   
//      println(buttons[i].walk.dataNodes.length);
      boolean anySelected = false;
      for (int l=0; l < (buttons[i].walk.dataLegs.length); l++){
        for (int k=0; k+1 < buttons[i].walk.dataLegs[l].dataNodes.length; k++){
          if (buttons[i].walk.dataLegs[l].dataNodes[k].isSelected()){
            anySelected = true;
            presBut = i;
            presLeg = l;
            presNode = k;
          }
        }
      }
      for (int l=0; l < buttons[i].walk.dataLegs.length; l++){
        if (buttons[i].walk.dataLegs[l].legControl.mouseOverCheck(mouseX, mouseY)){
          buttons[i].walk.dataLegs[l].legControl.clicked();
        }
      }
      
      if (anySelected){
        for (int l=0; l < (buttons[i].walk.dataLegs.length); l++){    
          for (int k=0; k < (buttons[i].walk.dataLegs[l].dataNodes.length -1); k++){
            dataNode dn = buttons[i].walk.dataLegs[l].dataNodes[k];
            if (dn.isSelected()){
              buttons[i].walk.dataLegs[l].dataNodes[k].hasFocus = true;
              //minim.stop();
              //player = minim.loadFile(dn.bdrFileName);
              //println("Playing " + dn.bdrFileName);        
              //player.cue(0);
              acp.minim.stop();
              acp.loadFile(dn.bdrFileName, 'B');
              acp.loadFile(dn.gsrFileName, 'G');
            }else{
              buttons[i].walk.dataLegs[l].dataNodes[k].hasFocus = false;
            }
          }
        }
      }
    }
  }
  
  if (acp.mouseOverCheck(mouseX, mouseY)){
    acp.clicked(); 
  }
  
  char mute = acp.muteMouseOverCheck(mouseX, mouseY);
  println(mute);
  if (mute != 'N'){
    acp.muteClicked(mute); 
  }
}

public void keyPressed(){
  println("key pressed");
  if (buttons[presBut].hasfile){
    if (key == ' '){
      println("space pressed");
      acp.clicked();
    } else if (key == ','){
      selectPrevNode();
    } else if (key == '.'){
      selectNextNode();
    } else if (key == 'b'){
      acp.muteClicked('B');
    } else if (key == 'g'){
      acp.muteClicked('G');
    } else if (int(key) >= 49 && int(key) <= 57){
      int c = int(key)-48;
      if (buttons[presBut].walk.dataLegs.length >= c){
        buttons[presBut].walk.dataLegs[c-1].legControl.clicked();
      }
    }
  }
}

public void mouseMoved() {
  //println(mouseX);
  Marker hitMarker = map.getFirstHitMarker(mouseX, mouseY);
  if (hitMarker != null && hitMarker.getId() != "interest") {
    // Select current marker 
    hitMarker.setSelected(true);
    String hmId = (hitMarker.getId());
    print("hit marker " + hmId + ". ");
    for (Marker marker : map.getMarkers ()) {
      if (! hmId.equals(marker.getId())){
        marker.setSelected(false);
      }
    }
  } else {
    // Deselect all other markers
    for (Marker marker : map.getMarkers ()) {
      marker.setSelected(false);
    }
  }
}

public void addButton(int i) {
  if (activebutton<10) {
    if (buttons[i+1] == null) {
      println("making new button");
      buttons[i+1] = new button(1290, 20 + ((i+1)*30), i+1); 
      activebutton++;
    }
  }
}

public void selectSpecificNode(int node, int leg){
  print("selecting node : ");
  println(node);
  print("selecting leg : ");
  println(leg); 
  buttons[presBut].walk.dataLegs[leg].dataNodes[node].hasFocus = true;
  acp.minim.stop();
  acp.loadFile(buttons[presBut].walk.dataLegs[leg].dataNodes[node].bdrFileName, 'B');
  acp.loadFile(buttons[presBut].walk.dataLegs[leg].dataNodes[node].gsrFileName, 'G');
  int z = map.getZoomLevel();
  print("zoom is ");
  println(z);
  Location l =  buttons[presBut].walk.dataLegs[leg].dataNodes[node].getLocation();
  map.zoomAndPanTo(l, z);
}

public void selectNextNode(){
  resetAllNodes();
  if (presNode < (buttons[presBut].walk.dataLegs[presLeg].dataNodes.length -2)){
    presNode++;
  }else if (presLeg < (buttons[presBut].walk.dataLegs.length - 1)){
    presLeg++;
    presNode = 0;
  }else{
    presLeg =0;
    presNode = 0;
  }
  if (buttons[presBut].walk.dataLegs[presLeg].hidden){
    buttons[presBut].walk.dataLegs[presLeg].legControl.clicked();
  }
  selectSpecificNode(presNode, presLeg);
}

public void selectPrevNode(){
  resetAllNodes();
  if (presNode > 0){
    presNode--;
  }else if(presLeg > 0){
    presLeg--;
    presNode = (buttons[presBut].walk.dataLegs[presLeg].dataNodes.length -2);
    println(presNode, presLeg);
  }else{
    presLeg = buttons[presBut].walk.dataLegs.length - 1;
    presNode = (buttons[presBut].walk.dataLegs[presLeg].dataNodes.length -2);
  }
  if (buttons[presBut].walk.dataLegs[presLeg].hidden){
    buttons[presBut].walk.dataLegs[presLeg].legControl.clicked();
  }
  selectSpecificNode(presNode, presLeg);
}

public void resetAllNodes(){
  for (int i=0; i < activebutton; i++){
    if (buttons[i].hasfile){
      for (int l=0; l < buttons[i].walk.dataLegs.length; l++){
        for (int k=0; k < (buttons[i].walk.dataLegs[l].dataNodes.length - 1); k++){
          println(k);
          buttons[i].walk.dataLegs[l].dataNodes[k].hasFocus = false;
        }
      }
    }
  }
}

///############################################''''
//////////////#################CLAASSSSESS######################///////////////////////////////////////////////////

//###---button class---###
public class button {
  int xpos;
  int ypos;
  int xwidth = 50;
  int yheight = 20;
  int mynumb;
  color colfileshown;
  color colfilehidden;
  color colnofile;
  color colbase;
  color colhighlightfile;
  color colhighlightnofile;
  color colcurrent;
  color colstroke = color(240,240,250);
  boolean hasfile;
  //PFont dispfont = loadFont("LiberationSans-Bold.ttf");
  PFont dispfont = createFont("Liberation Sans Bold", 14);
  File file;
  datawalk walk;

  button(int xtemp, int ytemp, int no) {
    xpos = xtemp;
    ypos = ytemp;
    mynumb = no;
    colfileshown = color(200);
    colfilehidden = color(140);
    colnofile = color(40);
    colbase = colnofile;
    colhighlightfile = color(220);
    colhighlightnofile = color(80);
    colcurrent = colbase;
    hasfile = false;
  }

  void display() {
    fill(colcurrent);
    stroke(colstroke);
    rect(xpos, ypos, xwidth, yheight, 3);
  }

  void getFile() {
    selectInput("Select a file to process:", "fileAssociated", null, this);
  }

  boolean mouseOverCheck(float xm, float ym) {
    if (xm >= xpos && xm <= xpos+xwidth && 
      ym >= ypos && ym <= ypos+yheight) {
      if (hasfile){
        colcurrent = colhighlightfile;
        stroke(colstroke);
        fill(colcurrent);
        textFont(dispfont, 16);
        textAlign(RIGHT);
        String fn = file.getName();
        text(fn, xpos - 10, ypos + 15);
      }else{
        colcurrent = colhighlightnofile;
      }
      return true;
    } else {
      colcurrent = colbase;
      return false;
    }
  }

  void deleteDataset() {
    walk.hidePath();
    walk = null;
    file = null;
    hasfile = false;
    this.colbase = colnofile;
  }
  
  void showWalk(){
    walk.showPath();
    colbase = colfileshown; 
  }
  
  void hideWalk(){
    walk.hidePath();
    colbase = colfilehidden;
  }

  void fileAssociated(File selection) {
    if (selection == null) {
      println("Window was closed or the user hit cancel.");
    } else {
      println("User selected " + selection.getAbsolutePath());
      walk = new datawalk(selection);
      walk.fileready = true;
      walk.gotoStart();
      file = selection;
      hasfile = true;
      this.colbase = colfileshown;
      addButton(mynumb);
    }
  }
}

//###---datawalk class---###
class datawalk { 

  XML dataset;
  int myId =0;
  boolean hidden = false;
  int minvalue = 0;
  int maxvalue = 0;
  int mindur = 0;
  int maxdur = 0;
  File dataFile;
  boolean fileready = false;
  dataLeg[] dataLegs;
  //dataNode[] dataNodes;

  datawalk(File selection) {
    String filename = selection.getAbsolutePath();
    this.dataFile = selection;
    println(selection.getParent());
    this.dataset = loadXML(filename);
    this.analyseDataSet();
    this.myId = idTicker;
    idTicker++;
  }

  void analyseDataSet() {
    XML[] legs = dataset.getChildren("leg");    
    for (int l=0; l < legs.length; l++){
      XML[] readings = legs[l].getChildren("record");
      for (int i=0; i+1 < readings.length; i=i+1) {
        int intense = readings[i+1].getChild("intensity").getIntContent();
        if (intense > maxvalue) {
          maxvalue = intense;
        }
        int dur = readings[i+1].getChild("millisEnd").getIntContent() - readings[i+1].getChild("millisStart").getIntContent();
        if (dur > maxdur){
          maxdur = dur;
        }else if (dur < mindur || mindur == 0){
          mindur = dur; 
        }
      }
    }
    println("Max value is : " + maxvalue);
  }

  void gotoStart(){
    XML[] legs = dataset.getChildren("leg");
    XML[] readings = legs[0].getChildren("record");
    map.zoomAndPanTo(new Location(readings[0].getChild("lat").getFloatContent(),readings[0].getChild("lon").getFloatContent()), 16);
  }

  void drawDataSet() {
    println("Drawing dataset");
    XML[] legs = dataset.getChildren("leg");
    dataLegs = new dataLeg[legs.length];
    print("Data legs :");
    println(dataLegs);
    String dir = this.dataFile.getParent();
    for (int l=0; l < dataLegs.length; l++){
      dataLegs[l] = new dataLeg(l, legs.length, myId);
      dataLegs[l].drawPath(legs[l], dir,  this.myId, this.maxvalue, this.mindur, this.maxdur); 
      dataLegs[l].drawInterestPoints(legs[l]);
    }
    
    this.fileready = false;
  }
  
  void refresh() {
    for (int l=0; l < dataLegs.length; l++){
      dataLegs[l].refresh(); 
    }
  }
  
  void mouseOverCheck(int x, int y){
    for (int l=0; l < dataLegs.length; l++){
      dataLegs[l].legControl.mouseOverCheck(x,y); 
    }
  }

  void hidePath() {
    for (int l=0; l < dataLegs.length; l++) {
      for (int i=0; i+1 < dataLegs[l].dataNodes.length; i++) {     
        print("node : ");
        println(i);
        print("leg : ");
        println(l);
        dataLegs[l].dataNodes[i].setHidden(true);
        dataLegs[l].dataNodes[i].pathLine.setHidden(true);
      }
      for (int i=0; i < dataLegs[l].interestPoints.length; i++) {
        dataLegs[l].interestPoints[i].setHidden(true);
      }
      dataLegs[l].hidden = true;
      dataLegs[l].legControl.hidden = true;
      dataLegs[l].legControl.colbase = dataLegs[l].legControl.colLegHidden;
      dataLegs[l].legControl.setHidden(true);
    }
    hidden = true;
  }

  void showPath() {
    for (int l=0; l < dataLegs.length; l++) {
      for (int i=0; i+1 < dataLegs[l].dataNodes.length; i++) {
        dataLegs[l].dataNodes[i].setHidden(false);
        dataLegs[l].dataNodes[i].pathLine.setHidden(false);        
      }
      for (int i=0; i < dataLegs[l].interestPoints.length; i++) {
        dataLegs[l].interestPoints[i].setHidden(false);
      }
      dataLegs[l].hidden = false;
      dataLegs[l].legControl.hidden = false;
      dataLegs[l].legControl.colbase = dataLegs[l].legControl.colLegShown;    
      dataLegs[l].legControl.setHidden(false);
    }
    hidden = false;
  }
  
}

public class dataLeg{
  dataNode[] dataNodes;
  interestNode[] interestPoints;
  boolean hidden = false;
  legButton legControl;
  int leg;
  int butt;
  
  dataLeg(int legNo, int maxLegs, int buttNo){
    leg = legNo;
    butt = buttNo;
    legControl = new legButton(leg, maxLegs, butt);
  }
  
  void drawPath(XML leg, String dir, int walkId, int maxvalue, int mindur, int maxdur){
    XML[] readings = leg.getChildren("record");
    dataNodes = new dataNode[readings.length];
    for (int i=0; i+1 < readings.length; i++) {
      int id = readings[i].getChild("id").getIntContent();
      int millisSt = readings[i].getChild("millisStart").getIntContent();
      int millisTo = readings[i].getChild("millisEnd").getIntContent();
      float lat1 = readings[i].getChild("lat").getFloatContent();
      float lon1 = readings[i].getChild("lon").getFloatContent();
      float lat2 = readings[i+1].getChild("lat").getFloatContent();
      float lon2 = readings[i+1].getChild("lon").getFloatContent();
      int intense = readings[i].getChild("intensity").getIntContent();
      String timeStart = readings[i].getChild("timeStart").getContent();
      String timeEnd = readings[i].getChild("timeEnd").getContent();
      Location start = new Location(lat1, lon1);
      Location end = new Location(lat2, lon2);
      dataNodes[i] = new dataNode(start, end, dir, walkId, id, millisSt, millisTo, intense, maxvalue, timeStart, timeEnd, mindur, maxdur); 
      dataNodes[i].draw();
    } 
  }
  
  void drawInterestPoints(XML leg){
    XML[] readings = leg.getChildren("interest_point");
    interestPoints = new interestNode[readings.length];
    for (int i=0; i < readings.length; i++) {
      float lat = readings[i].getChild("lat").getFloatContent();
      float lon = readings[i].getChild("lon").getFloatContent();
      ArrayList<Location> loc = new ArrayList<Location>();
      loc.add(new Location(lat+0.00006, lon));
      loc.add(new Location(lat+0.00017, lon+0.0001));
      loc.add(new Location(lat+0.00017, lon-0.0001));
      interestPoints[i] = new interestNode(loc);
      interestPoints[i].setColor(color(200,200,170,200));
      interestPoints[i].setHighlightColor(color(200,200,90,200));
      interestPoints[i].setStrokeColor(color(240,240,180,200));
      interestPoints[i].setHighlightStrokeColor(color(240,240,12,200));
      map.addMarker(interestPoints[i]);
    } 
  }
  
  void showLeg() {
    for (int i=0; i+1 < dataNodes.length; i++) {
      dataNodes[i].setHidden(false);
      dataNodes[i].pathLine.setHidden(false);
    }
    for (int i=0; i < interestPoints.length; i++) {
      interestPoints[i].setHidden(false);
    }
    hidden = false;
  }
  
  void hideLeg() {
    for (int i=0; i+1 < dataNodes.length; i++) {
      dataNodes[i].setHidden(true);
      dataNodes[i].pathLine.setHidden(true);
    }
    for (int i=0; i < interestPoints.length; i++) {
      interestPoints[i].setHidden(true);
    }
    hidden = true;    
  }
  
  void refresh(){
    legControl.display();
    for (int i=0; i+1 < dataNodes.length; i++){
      this.dataNodes[i].refresh();  
    } 
  }
}

public class interestNode extends SimplePolygonMarker{
  
  public interestNode(ArrayList<Location> loc){
    super(loc);
    this.id = "interest";
  }
 
}

public class dataNode extends SimplePointMarker{
  String directory;
  String bdrFileName;
  String gsrFileName;
  String interviewFiles[];
  Location lineStart;
  Location lineEnd;
  int myId;
  int millisSt;
  int millisTo;
  int intense;
  int maxvalue;
  int mindur;
  int maxdur;
  String timeSt;
  String timeTo;
  boolean hasFocus = false;
  SimpleLinesMarker pathLine;
  
  public dataNode(Location start, Location end, String dir, int walkId, int myId, int myMillisSt, int myMillisTo, int intense, int max, String timeStart, String timeEnd, int minduration, int maxduration) {
    super(start);
    this.lineStart = start;
    this.lineEnd = end;
    this.myId = myId;
    this.intense = intense;
    this.maxvalue = max;
    this.directory = dir;
    this.timeSt = timeStart;
    this.timeTo = timeEnd;
    this.bdrFileName = dir + "/snd/" + myId + ".mp3";
    this.gsrFileName = dir + "/sndGSR/" + myId + ".wav";
    String sId = new Integer(myId).toString();
    String sWalkId = new Integer(walkId).toString();
    this.id = sWalkId + "-" + sId;
    println(this.id);
    this.millisSt = myMillisSt;
    this.millisTo = myMillisTo;
    this.pathLine = pathLine;
    this.mindur = minduration;
    this.maxdur = maxduration;
  }
  
  public void draw(){
    float weight = map(millisTo - millisSt,this.mindur,this.maxdur,6,13);
    if (this.isSelected()){
      this.setColor(color(50, 50, 50, 120));
      this.setStrokeColor(color(200, 200, 200));
      this.setStrokeWeight(2);
      this.setRadius(weight + 1f);
      println("selected");
      drawPathLine(this.lineStart, this.lineEnd, this.intense, 255); 
    }else{
      this.setColor(color(250, 250, 250, 120));
      this.setStrokeColor(color(250, 250, 250, 80));
      this.setStrokeWeight(1);
      this.setRadius(weight);
      drawPathLine(this.lineStart, this.lineEnd, this.intense, 0); 
    }
    map.addMarkers(this);
  }
  
  public void refresh(){
    float weight = map(millisTo - millisSt,this.mindur,this.maxdur,4,12);  
    if (this.hasFocus){
      this.setColor(color(255, 255, 255, 140));
      this.setHighlightColor(color(50, 50, 50, 120));
      this.setStrokeColor(color(255, 255, 255));
      this.setStrokeWeight(2);
      this.setRadius(weight + 1f);
      refreshPathLine(this.intense, 170);       
    }else if(this.isSelected()){
      this.setColor(color(50, 50, 50, 120));
      this.setHighlightColor(color(50, 50, 50, 120));
      this.setStrokeColor(color(255, 255, 255));
      this.setStrokeWeight(2);
      this.setRadius(weight + 1f);
      refreshPathLine(this.intense, 120); 
    }else{
      this.setColor(color(250, 250, 250, 120));
      this.setHighlightColor(color(50, 50, 50, 120));
      this.setStrokeColor(color(250, 250, 250, 80));
      this.setStrokeWeight(1);
      this.setRadius(weight);
      refreshPathLine(this.intense, 60); 
    }    
  }
  
  public int getMyId(){
    int rtn = this.myId;
    return rtn; 
  }
  
  void refreshPathLine(int intense, int hl){
    int red = int(map(intense, 0, this.maxvalue, 0, 255));
    int blue = int(map(intense, 0, this.maxvalue, 180, 30));
    int linecolor = color(red, hl, blue, 200);
//    int highlightcolor = color(red, hl, 150-(intense*2), 200);
    this.pathLine.setColor(linecolor);
    this.pathLine.setHighlightColor(linecolor);
    int weight = 3+int(map(intense,0,maxvalue,0,20));
    this.pathLine.setStrokeWeight(weight);
  }
  
  void drawPathLine(Location start, Location end, int intense, int hl) {
    SimpleLinesMarker line = new SimpleLinesMarker(start, end);
    int red = int(map(intense, hl, this.maxvalue, 0, 255));
    int blue = int(map(intense, hl, this.maxvalue, 180, 30));
    int linecolor = color(red, 60, blue, 200);
    int highlightcolor = color(red, 90, 150-(intense*2), 200);
    line.setColor(linecolor);
    line.setHighlightColor(linecolor);
    int weight = 3+int(map(intense,0,maxvalue,0,20));
    line.setStrokeWeight(weight);
    //    println("added line :)");
    map.addMarkers(line);
    this.pathLine = line;
  }
  
}

public class audControl{
  
  color colActive = color(50);
  PFont dispfont = createFont("Liberation Sans Bold", 14);
  color colMute = color(50);
  color colInactive = color(140);
  color colActiveHighlight = color(80);
  color colInactiveHighlight = color(140);
  color colStroke = color(20);
  color colBase = colInactive;
  color colHighlight = colInactiveHighlight;
  color colCurrent = colBase;
  color colBox = color(230,230,250); 
  color colBoxStroke = color(250);
  boolean active = false;
  int xPos;
  int yPos;
  int backBoxWidth = 270;
  int mode;  
  ControlP5 cp5;
  Minim minim;
  AudioPlayer playerBD;
  AudioPlayer playerGSR;
  boolean muteBD = false;
  boolean muteGSR = false;
  int yPosBD;
  int yPosGSR;
  int xPosMute;
  Slider audPos;
  
  audControl(int x, int y, int m, Minim mi, ControlP5 controlP5){
    this.drawPlayShape();
    this.minim = mi;
    xPos = x;
    yPos = y;
    yPosBD = yPos-11;
    yPosGSR = yPos+13;
    xPosMute = xPos + backBoxWidth + 5;
    mode = m;
    cp5 = controlP5;
    audPos = cp5.addSlider("audPosMillis")
      .setPosition(xPos+30, yPos +6)
      .setSize(this.backBoxWidth-50, 8)
      .setLabelVisible(false)
      .setRange(0,500);
  }

  void display(){
    dispBackBox();
    if (! active){
      drawPlayShape();
    } else if (playerBD.isPlaying()){
      drawPauseShape();
      dispSoundTime();
      dispLeg();
      dispGPSTime();
      dispSlider();
    } else {
      drawPlayShape();
      dispSoundTime();
      dispLeg();
      dispGPSTime();
      dispSlider();
    }
    dispMuteButton('B');
    dispMuteButton('G');
  }
  
  void dispSlider(){
    float tpos = this.playerBD.position();
    float dur = this.playerBD.length()/2;
    this.audPos.setRange(0,dur);
    int valueColor = color(0,0,0, 250);
    int backColor = color(0,0,0, 250);
    int activeColor = color(0,0,0, 250);
    if (buttons[presBut].hasfile){
      int intense = buttons[presBut].walk.dataLegs[presLeg].dataNodes[presNode].intense;
      int maxvalue = buttons[presBut].walk.maxvalue;
      int red = int(map(intense, 0, maxvalue, 0, 255));
      int blue = int(map(intense, 0, maxvalue, 180, 30));
      activeColor = color(red, 180, blue, 250);
      valueColor = color(red, 140, blue, 250);
      backColor = color(red, 40, blue, 250);
    }
    if (this.audPos.isMousePressed()){
      int p = int(this.audPos.getValue());
      this.playerBD.cue(p);
      this.playerGSR.cue(p); 
    }else{   
      this.audPos.setValue(int(tpos));
      audPosMillis = int(tpos);
    }
    this.audPos.setColorActive(activeColor)
      .setColorForeground(valueColor)
      .setColorBackground(backColor);
  }

  void dispSoundTime(){
    fill(colCurrent);
    stroke(colStroke);
    textFont(dispfont, 12);
    textAlign(LEFT);
    float tpos = (this.playerBD.position());
    float dur = (this.playerBD.length()/2);
    //println(tpos);
    String sTpos = nf(tpos/1000, 1, 1);
    String sDur = nf(dur/1000, 1, 1);
    text(sTpos + '/' + sDur + " secs", xPos + 30, yPos + 25); 
  }
  
  void dispMuteButton(char playerSelect){
    color colMuteBox = this.colBox;
    int yMutePos = 0;
    if (playerSelect == 'B'){
      yMutePos = yPosBD;
      if(this.muteBD){
        colMuteBox = this.colMute;
      }
    }else if (playerSelect == 'G'){
      yMutePos = yPosGSR;
      if(this.muteGSR){
        colMuteBox = this.colMute;
      }
    }
    fill(colMuteBox);
    stroke(this.colBoxStroke);
    rect(this.xPosMute, yMutePos, 18, 18, 3); 
    fill(colCurrent);
    stroke(colStroke);
    textFont(dispfont, 10);
    textAlign(LEFT);    
    text(playerSelect, xPosMute + 6, yMutePos + 13); 
  }
  
  void dispGPSTime(){
    fill(colCurrent);
    stroke(colStroke);
    textFont(dispfont, 10);
    textAlign(LEFT);    
    String tSt = buttons[presBut].walk.dataLegs[presLeg].dataNodes[presNode].timeSt;
    String tTo = buttons[presBut].walk.dataLegs[presLeg].dataNodes[presNode].timeTo;
    text("Time: " + tSt + " - " + tTo, xPos + 125, yPos + 2); 
  }
  
  void dispLeg(){
    fill(colCurrent);
    stroke(colStroke);
    textFont(dispfont, 10);
    textAlign(LEFT);
    String leg = str(presLeg + 1);
    String node = str(presNode + 1);
    String ttl = str(buttons[presBut].walk.dataLegs[presLeg].dataNodes.length - 2);
    text("Leg: " + leg + "  Section: " + node, xPos + 30, yPos + 2); 
  }

  void loadFile(String filename, char playerSelect){
    if (new File(filename).isFile()){
      
      println(filename);
      if (playerSelect == 'B'){
        if (playerBD != null){
          this.playerBD.pause();
        }
        this.playerBD = this.minim.loadFile(filename);
        this.playerBD.cue(0);
        println("BD file loaded");
        if (muteBD){
          playerBD.mute(); 
        }
      }else if (playerSelect == 'G'){
          if (playerGSR != null){
            this.playerGSR.pause();
          }
        this.playerGSR = this.minim.loadFile(filename);
        this.playerGSR.setGain(-15.0);
        this.playerGSR.cue(0);
        println("GSR file loaded");      
        if (muteGSR){
          playerGSR.mute(); 
        }
      }else{
        println("player selection not recognised"); 
      }
      this.active = true;
      colBase = colActive;
      colHighlight = colActiveHighlight;
    } else {
      println("Cannot find file " + filename); 
      if (playerSelect == 'B'){
        this.active = false;
        colBase = colInactive;
        colHighlight = colInactiveHighlight;
      }
    }
  }
  
  void dispBackBox(){ 
    fill(this.colBox);
    rect(xPos-10, yPos -10, this.backBoxWidth, 40, 3);
  }
  
  void clicked(){
    if (this.active){
      if (this.mode == 0){
        this.playTrack();
      }
    }  
  }
  
  void playTrack(){
    print("posistion BD ");
    print(playerBD.position());
    print("GSR ");
    print(playerGSR.position());
    print(" length  : ");
    println(playerBD.length());
    if(playerBD.isPlaying()){
      playerBD.pause();
      playerGSR.pause();
    }else{
      playerBD.play();
      playerGSR.play();
    }
    if ((playerBD.position() >= ((playerBD.length()/2) -100))){// || (playerGSR.position() >= ((playerGSR.length()/2) -100))){
      println("player overtime");
      playerBD.cue(0);
      playerGSR.cue(0);
      playerBD.play();
      playerGSR.play();
    }
  }
  
  boolean mouseOverCheck(float xm, float ym){
    if (xm >= this.xPos && xm <= this.xPos + this.backBoxWidth &&
    ym >= this.yPos && ym <= this.yPos + 30){
     // println("setting map off");
      map.setActive(false);
    }else{
      map.setActive(true); 
    }
    if (xm >= this.xPos && xm <= this.xPos+18 && 
    ym >= this.yPos && ym <= this.yPos+20){
      this.colCurrent = colHighlight;
      return true;
    }else{
      this.colCurrent = colBase;
      return false;
    }
  }
  
  char muteMouseOverCheck(float xm, float ym){
    char rtn;
    if (xm >= xPosMute && xm <= xPosMute+18){
       if(ym >= yPosBD && ym <= yPos+18){
         rtn = 'B';
       }else if (ym >= yPosGSR && ym <= yPosGSR+18){
         rtn = 'G';
       }else{
         rtn = 'N'; 
       }
    }else{
      rtn = 'N';
    }
    return rtn;
  }
  
  void muteClicked(char playerSelect){
    println("mute clicked");
    if (playerSelect == 'B'){
      if (muteBD){
        muteBD = false;
        if (playerBD != null){
          playerBD.unmute();
        } 
      }else{
        muteBD = true;
        if (playerBD != null){
          playerBD.mute();
        } 
      }
    } else if (playerSelect == 'G'){
      if (muteGSR){
        muteGSR = false;
        if (playerGSR != null){
          playerGSR.unmute();
        }
      }else{
        muteGSR = true;
        if (playerGSR != null){
          playerGSR.mute();
        }
      } 
    }
  }

  void drawPlayShape(){
    stroke(colStroke);
    fill(colCurrent);
    triangle(xPos, yPos, xPos + 18, yPos + 10, xPos, yPos+20);
  }

  void drawPauseShape(){
    stroke(colStroke);
    fill(colCurrent);
    rect(xPos+3, yPos, 5, 20);
    rect(xPos+12, yPos, 5, 20);
  }  
  
}

class legButton{
  boolean hidden = false;
  int legNo;
  int buttonNo;
  int xpos;
  int ypos;
  int xwidth = 20;
  int yheight = 20;
  color colLegShown = color(200);
  color colLegHidden = color(40);
  color colbase;
  color colhighlightLegShown = color(220);
  color colhighlightLegHidden = color(60);
  color coltext = color (90);
  color colcurrent;
  color colstroke = color(240,240,250);
  PFont dispfont = createFont("Liberation Sans Bold", 14);
  
  legButton(int leg, int legMax, int button) {
    legNo = leg;
    buttonNo = button;
    xpos = legInterStart + (legNo * (legBarWidth/(legMax-1)));
    ypos = lowerInterfaceYPos;
    colbase = colLegShown;
    colcurrent = colbase;
  }

  void display() {
    if(hidden == false){
      fill(colcurrent);
      stroke(colstroke);
      rect(xpos, ypos, xwidth, yheight, 3);
      fill(coltext);
      stroke(coltext);
      textFont(dispfont, 11);
      textAlign(LEFT);
      String sLegNo = nf(legNo+1,1,0);    
      text(sLegNo, xpos + 7, ypos + 14); 
    }
  }

  void clicked(){
    if (buttons[buttonNo].walk.dataLegs[legNo].hidden){
      buttons[buttonNo].walk.dataLegs[legNo].showLeg();
      colbase = colLegShown;
    }else{
      buttons[buttonNo].walk.dataLegs[legNo].hideLeg();
      colbase = colLegHidden;
    }
  }

  void setHidden(boolean hide){  
    hidden = hide;
  }
  
  boolean mouseOverCheck(float xm, float ym) {
    if (xm >= xpos && xm <= xpos+xwidth && 
      ym >= ypos && ym <= ypos+yheight) {
      if (buttons[buttonNo].walk.dataLegs[legNo].hidden){
        colcurrent = colhighlightLegHidden;
      }else{
        colcurrent = colhighlightLegShown;
      }
      return true;
    } else {
      colcurrent = colbase;
      return false;
    }
  }
  
}

class legBar{

  legBar(){
    this.display();
  }
  
  void display(){
    fill(color(110));
    stroke(color(240));
    rect(legInterStart + 10, lowerInterfaceYPos+5, legBarWidth, 10, 3);
  }
}
