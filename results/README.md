# results/

Mỗi lần chạy chính thức có một thư mục riêng:

```
results/<tool>/<version>/<tool>_<version>_<config>_run<k>/
├── MACHINE.md     # bash scripts/machine_info.sh > MACHINE.md
├── command.txt    # lệnh đã chạy, nguyên văn
├── summary.txt    # số liệu chính: thời gian, exec/s, coverage, số crash, số lỗi sau khi gộp
└── ...            # log nhỏ, file thống kê (plot_data, fuzzer_stats), ảnh chụp
```

Ví dụ: `results/aflpp/4.9.2/aflpp_4.9.2_asan_run1/`.

Chỉ commit file nhỏ dạng text hoặc ảnh. Output đầy đủ của fuzzer và file gây crash thì nén lại, đưa lên thư mục `02_runs/` hoặc `03_crashes/` trên Drive, rồi ghi đường dẫn vào `summary.txt` hoặc cột `drive_path` của `triage/bugs.csv`.

Mọi con số đưa vào slide hay báo cáo phải có nguồn trong thư mục này.
