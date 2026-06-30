bambu lanciato dopo aver eseguito fix all con comando:

nohup ~/bambu.ginevra2.AppImage --top-fname=myproject   -I firmware/ac_types   --generate-interface=INFER   --clock-period=40   --bambu-parameter=inline-max-cost=0   --simulate   --generate-tb=myproject_test.cpp   --verbosity=4   firmware/myproject.cpp   > bambu_log_sim.txt 2>&1 & echo "PID: $!"


L'output preciso si può trovare sulla vm alla cartella /dambrosi/12_5

