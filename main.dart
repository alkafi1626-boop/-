import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const App());

class Task {
  String id, title, priority, repeat;
  DateTime date;
  TimeOfDay time;
  bool done, reminder;

  Task({
    required this.id, required this.title, required this.date,
    required this.time, this.priority='মাঝারি', this.repeat='একবার',
    this.done=false, this.reminder=false,
  });

  Map<String,dynamic> toJson()=> {
    'id':id,'title':title,'date':date.toIso8601String(),
    'hour':time.hour,'minute':time.minute,'priority':priority,
    'repeat':repeat,'done':done,'reminder':reminder
  };

  factory Task.fromJson(Map<String,dynamic> j)=>Task(
    id:j['id'], title:j['title'], date:DateTime.parse(j['date']),
    time:TimeOfDay(hour:j['hour']??9,minute:j['minute']??0),
    priority:j['priority']??'মাঝারি', repeat:j['repeat']??'একবার',
    done:j['done']??false, reminder:j['reminder']??false
  );
}

class App extends StatefulWidget {
  const App({super.key});
  State<App> createState()=>_AppState();
}
class _AppState extends State<App>{
  bool dark=false;
  Widget build(BuildContext c)=>MaterialApp(
    debugShowCheckedModeBanner:false,title:'আমার পরিকল্পনা',
    themeMode:dark?ThemeMode.dark:ThemeMode.light,
    theme:ThemeData(colorSchemeSeed:Colors.indigo,useMaterial3:true),
    darkTheme:ThemeData.dark(useMaterial3:true),
    home:Home(onTheme:(v)=>setState(()=>dark=v)),
  );
}

class Home extends StatefulWidget{
  final ValueChanged<bool> onTheme;
  const Home({super.key,required this.onTheme});
  State<Home> createState()=>_HomeState();
}
class _HomeState extends State<Home>{
  int tab=0;
  DateTime day=DateTime.now();
  List<Task> tasks=[];
  String goal='';
  late SharedPreferences prefs;

  final months=['জানুয়ারি','ফেব্রুয়ারি','মার্চ','এপ্রিল','মে','জুন','জুলাই','আগস্ট','সেপ্টেম্বর','অক্টোবর','নভেম্বর','ডিসেম্বর'];
  final weekdays=['সোম','মঙ্গল','বুধ','বৃহস্পতি','শুক্র','শনি','রবি'];

  void initState(){super.initState();load();}
  Future<void> load() async{
    prefs=await SharedPreferences.getInstance();
    final s=prefs.getString('tasks')??'[]';
    setState((){
      tasks=(jsonDecode(s) as List).map((x)=>Task.fromJson(x)).toList();
      goal=prefs.getString('goal')??'';
    });
  }
  Future<void> save() async{
    await prefs.setString('tasks',jsonEncode(tasks.map((x)=>x.toJson()).toList()));
    await prefs.setString('goal',goal);
  }
  bool same(DateTime a,DateTime b)=>a.year==b.year&&a.month==b.month&&a.day==b.day;
  List<Task> get today=>tasks.where((x)=>same(x.date,day)).toList()..sort((a,b)=>(a.time.hour*60+a.time.minute).compareTo(b.time.hour*60+b.time.minute));

  String dateLine(DateTime d){
    final h=_hijri(d);
    return '${d.day} ${months[d.month-1]} ${d.year}  •  ${weekdays[d.weekday-1]}  •  ${h.d} ${h.name} ${h.y} হিজরি';
  }

  Future<void> taskDialog({Task? edit}) async{
    final title=TextEditingController(text:edit?.title??'');
    DateTime date=edit?.date??day;
    TimeOfDay time=edit?.time??const TimeOfDay(hour:9,minute:0);
    String priority=edit?.priority??'মাঝারি';
    String repeat=edit?.repeat??'একবার';
    bool reminder=edit?.reminder??false;

    await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
      title:Text(edit==null?'নতুন কাজ':'কাজ সম্পাদনা'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'কাজের নাম')),
        ListTile(contentPadding:EdgeInsets.zero,title:const Text('তারিখ'),subtitle:Text('${date.day}/${date.month}/${date.year}'),
          onTap:()async{final x=await showDatePicker(context:ctx,initialDate:date,firstDate:DateTime(2020),lastDate:DateTime(2100));if(x!=null)setD(()=>date=x);}),
        ListTile(contentPadding:EdgeInsets.zero,title:const Text('সময়'),subtitle:Text(time.format(ctx)),
          onTap:()async{final x=await showTimePicker(context:ctx,initialTime:time);if(x!=null)setD(()=>time=x);}),
        DropdownButtonFormField(value:priority,decoration:const InputDecoration(labelText:'অগ্রাধিকার'),
          items:['জরুরি','উচ্চ','মাঝারি','কম'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
          onChanged:(x)=>setD(()=>priority=x??'মাঝারি')),
        DropdownButtonFormField(value:repeat,decoration:const InputDecoration(labelText:'পুনরাবৃত্তি'),
          items:['একবার','প্রতিদিন','প্রতি সপ্তাহে','প্রতি মাসে'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
          onChanged:(x)=>setD(()=>repeat=x??'একবার')),
        SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('রিমাইন্ডার চালু'),value:reminder,onChanged:(x)=>setD(()=>reminder=x)),
        if(reminder) const Align(alignment:Alignment.centerLeft,child:Text('নোটিফিকেশন ইঞ্জিন পরবর্তী Android build-এ যুক্ত হবে।',style:TextStyle(fontSize:12))),
      ])),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('বাতিল')),
        FilledButton(onPressed:(){
          if(title.text.trim().isEmpty)return;
          setState((){
            if(edit==null) tasks.add(Task(id:DateTime.now().microsecondsSinceEpoch.toString(),title:title.text.trim(),date:date,time:time,priority:priority,repeat:repeat,reminder:reminder));
            else{edit.title=title.text.trim();edit.date=date;edit.time=time;edit.priority=priority;edit.repeat=repeat;edit.reminder=reminder;}
          });
          save();Navigator.pop(ctx);
        },child:const Text('সংরক্ষণ'))
      ]
    )));
  }

  void delete(Task t){setState(()=>tasks.removeWhere((x)=>x.id==t.id));save();}
  Widget card(Task t)=>Card(child:ListTile(
    leading:Checkbox(value:t.done,onChanged:(v){setState(()=>t.done=v??false);save();}),
    title:Text(t.title,style:TextStyle(decoration:t.done?TextDecoration.lineThrough:null)),
    subtitle:Text('${t.time.format(context)} • ${t.priority} • ${t.repeat}${t.reminder?' • 🔔':''}'),
    trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit')taskDialog(edit:t);if(v=='del')delete(t);},itemBuilder:(_)=>const[
      PopupMenuItem(value:'edit',child:Text('সম্পাদনা')),
      PopupMenuItem(value:'del',child:Text('মুছে ফেলুন'))
    ])
  ));

  Widget home()=>ListView(padding:const EdgeInsets.all(16),children:[
    Text('আমার পরিকল্পনা',style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.bold)),
    const SizedBox(height:6),Text(dateLine(day)),
    const SizedBox(height:16),
    Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('এই মাসের প্রধান লক্ষ্য',style:TextStyle(fontWeight:FontWeight.bold)),
      TextField(controller:TextEditingController(text:goal),decoration:const InputDecoration(hintText:'লক্ষ্য লিখুন'),onChanged:(v){goal=v;save();})
    ]))),
    const SizedBox(height:12),
    Row(children:[
      Expanded(child:stat('আজ',today.length)),
      const SizedBox(width:8),Expanded(child:stat('সম্পন্ন',today.where((x)=>x.done).length)),
      const SizedBox(width:8),Expanded(child:stat('মোট',tasks.length))
    ]),
    const SizedBox(height:16),
    Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('আজকের কাজ',style:Theme.of(context).textTheme.titleLarge),IconButton(onPressed:()=>taskDialog(),icon:const Icon(Icons.add_circle))]),
    if(today.isEmpty)const Padding(padding:EdgeInsets.all(20),child:Center(child:Text('আজ কোনো কাজ নেই।'))),
    ...today.map(card)
  ]);

  Widget stat(String a,int n)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[Text('$n',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),Text(a)])));

  Widget calendar(){
    final first=DateTime(day.year,day.month,1), count=DateTime(day.year,day.month+1,0).day;
    return ListView(padding:const EdgeInsets.all(16),children:[
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        IconButton(onPressed:()=>setState(()=>day=DateTime(day.year,day.month-1,1)),icon:const Icon(Icons.chevron_left)),
        Text('${months[day.month-1]} ${day.year}',style:Theme.of(context).textTheme.titleLarge),
        IconButton(onPressed:()=>setState(()=>day=DateTime(day.year,day.month+1,1)),icon:const Icon(Icons.chevron_right))
      ]),
      GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:7,children:[
        ...weekdays.map((x)=>Center(child:Text(x))),
        ...List.generate(first.weekday-1,(_)=>const SizedBox()),
        ...List.generate(count,(i){final d=DateTime(day.year,day.month,i+1);final selected=same(d,day);final n=tasks.where((t)=>same(t.date,d)).length;
          return InkWell(onTap:()=>setState(()=>day=d),child:Card(color:selected?Theme.of(context).colorScheme.primaryContainer:null,child:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text('${i+1}'),if(n>0)Text('•'* (n>3?3:n))]))));
        })
      ]),
      const SizedBox(height:16),Text(dateLine(day)),...today.map(card)
    ]);
  }

  Widget plan()=>ListView(padding:const EdgeInsets.all(16),children:[
    Text('পরিকল্পনা',style:Theme.of(context).textTheme.headlineSmall),
    const SizedBox(height:8),
    const Text('একটি বড় লক্ষ্যকে ছোট ছোট দৈনিক কাজে ভাগ করুন।'),
    const SizedBox(height:12),
    Card(child:ListTile(leading:const Icon(Icons.flag),title:const Text('মাসিক লক্ষ্য'),subtitle:Text(goal.isEmpty?'লক্ষ্য এখনো লেখা হয়নি':goal))),
    FilledButton.icon(onPressed:()=>taskDialog(),icon:const Icon(Icons.add),label:const Text('কাজ যোগ করুন')),
    const SizedBox(height:8),
    ...tasks.map(card)
  ]);

  Widget progress(){
    final done=tasks.where((x)=>x.done).length;final p=tasks.isEmpty?0.0:done/tasks.length;
    return ListView(padding:const EdgeInsets.all(16),children:[
      Text('অগ্রগতি',style:Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height:20),
      Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[
        SizedBox(width:140,height:140,child:Stack(alignment:Alignment.center,children:[CircularProgressIndicator(value:p,strokeWidth:12),Text('${(p*100).round()}%',style:const TextStyle(fontSize:25,fontWeight:FontWeight.bold))])),
        const SizedBox(height:12),Text('$doneটি সম্পন্ন • ${tasks.length-done}টি বাকি')
      ])))
    ]);
  }

  Widget settings()=>ListView(padding:const EdgeInsets.all(16),children:[
    Text('সেটিংস',style:Theme.of(context).textTheme.headlineSmall),
    SwitchListTile(title:const Text('ডার্ক মোড'),value:Theme.of(context).brightness==Brightness.dark,onChanged:widget.onTheme),
    const ListTile(leading:Icon(Icons.lock_open),title:Text('লগইন নেই'),subtitle:Text('অ্যাপ সরাসরি খুলবে।')),
    const ListTile(leading:Icon(Icons.notifications),title:Text('রিমাইন্ডার'),subtitle:Text('কাজে রিমাইন্ডার চিহ্ন সংরক্ষণ করা যায়।')),
    ListTile(leading:const Icon(Icons.download),title:const Text('ডেটা ব্যাকআপ'),subtitle:const Text('পরবর্তী ধাপে Export/Import যুক্ত করা হবে।')),
    ListTile(leading:const Icon(Icons.info_outline),title:const Text('সংস্করণ'),subtitle:const Text('V3 • আমার পরিকল্পনা'))
  ]);

  Widget build(BuildContext c){
    final pages=[home(),calendar(),plan(),progress(),settings()];
    return Scaffold(
      appBar:AppBar(title:const Text('আমার পরিকল্পনা'),actions:[IconButton(onPressed:()=>setState(()=>day=DateTime.now()),icon:const Icon(Icons.today))]),
      body:pages[tab],
      floatingActionButton:(tab==0||tab==2)?FloatingActionButton(onPressed:()=>taskDialog(),child:const Icon(Icons.add)):null,
      bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:const[
        NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'হোম'),
        NavigationDestination(icon:Icon(Icons.calendar_month_outlined),selectedIcon:Icon(Icons.calendar_month),label:'ক্যালেন্ডার'),
        NavigationDestination(icon:Icon(Icons.edit_calendar_outlined),selectedIcon:Icon(Icons.edit_calendar),label:'পরিকল্পনা'),
        NavigationDestination(icon:Icon(Icons.insights_outlined),selectedIcon:Icon(Icons.insights),label:'অগ্রগতি'),
        NavigationDestination(icon:Icon(Icons.settings_outlined),selectedIcon:Icon(Icons.settings),label:'সেটিংস')
      ])
    );
  }

  _H hijri(DateTime d){
    final jd=d.millisecondsSinceEpoch/86400000+2440587.5;
    final z=(jd+0.5).floor(), l=z-1948440+10632, n=((l-1)/10631).floor(), ll=l-10631*n+354;
    final j=(((10985-ll)/5316).floor())*(((50*ll)/17719).floor())+((ll/5670).floor())*(((43*ll)/15238).floor());
    final q=ll-(((30-j)/15).floor())*((17719*j)/50).floor()-((j/16).floor())*((15238*j)/43).floor()+29;
    final m=((24*q)/709).floor(), day=q-((709*m)/24).floor(), y=30*n+j-30;
    const names=['মুহররম','সফর','রবিউল আউয়াল','রবিউস সানি','জমাদিউল আউয়াল','জমাদিউস সানি','রজব','শাবান','রমজান','শাওয়াল','জিলকদ','জিলহজ'];
    return _H(day,m,y,names[m-1]);
  }
}
class _H{int d,m,y;String name;_H(this.d,this.m,this.y,this.name);}
