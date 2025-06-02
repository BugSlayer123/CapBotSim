use clap::Parser;
use gnuplot::{
    AutoOption, AxesCommon, Caption, Color, Coordinate, Figure, LabelOption, MarginSide,
    PlotOption::LineWidth,
};
use serde::Deserialize;
use std::{collections::HashMap, path::Path, u64};

#[derive(Parser, Debug)]
#[command(version, about)]
struct Args {
    #[arg(long, required = true, num_args = 1.., value_delimiter = ' ')]
    log_files: Vec<String>,

    #[arg(long, required = true, num_args = 1.., value_delimiter = ',')]
    names: Vec<String>,
}

#[derive(Debug, Deserialize)]
struct Record {
    //    iteration: u64,
    tick: u64,
    //    #[serde(deserialize_with = "parse_data_field")]
    //    data: Vec<u8>,
}

fn moving_average(data: &[f64], window_size: usize) -> Vec<f64> {
    let mut avg = Vec::new();
    for i in 0..data.len() {
        let start = if i >= window_size { i - window_size + 1 } else { 0 };
        let window = &data[start..=i];
        let sum: f64 = window.iter().sum();
        avg.push(sum / window.len() as f64);
    }
    avg
}

fn parse_data_field<'de, D>(deserializer: D) -> Result<Vec<u8>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    let s: String = Deserialize::deserialize(deserializer)?;
    if s.trim().is_empty() {
        return Ok(Vec::new());
    }
    s.split(',')
        .map(|s| s.trim().parse::<u8>().map_err(serde::de::Error::custom))
        .collect()
}

fn parse_csv(path: &str) -> Result<Vec<Record>, Box<dyn std::error::Error>> {
    let file = std::fs::File::open(path)?;
    let mut rdr = csv::Reader::from_reader(file);
    let mut records = Vec::new();
    for result in rdr.deserialize() {
        let record: Record = result?;
        records.push(record);
    }
    Ok(records)
}

fn ticks_to_minutes(ticks: u64) -> u64 {
    (ticks as f64 / (60.0 * 60.0)) as u64
}

fn get_filename_without_ext(path: &str) -> String {
    Path::new(path)
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("unknown")
        .to_string()
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    let colors = [
        "red", "blue", "green", "purple", "orange", "black", "brown", "cyan",
    ];

    let mut all_times_counts: Vec<(Vec<u64>, Vec<f64>, String)> = Vec::new();

    for (idx, log_file) in args.log_files.iter().enumerate() {
        let display_name = args.names[idx].clone();
        println!("Processing file: {} ({})", log_file, display_name);

        let records = parse_csv(log_file).expect(&format!("Error reading records from {}", log_file));

        let mut time_counts: HashMap<u64, u32> = HashMap::new();
        for record in &records {
            let minutes = ticks_to_minutes(record.tick);
            *time_counts.entry(minutes).or_insert(0) += 1;
        }

        let mut times: Vec<u64> = time_counts.keys().cloned().collect();
        times.sort_by(|a, b| a.partial_cmp(b).unwrap());

        let total_simulations = records.len() as f64;

        let counts: Vec<f64> = times
            .iter()
            .map(|time| *time_counts.get(time).unwrap() as f64 / total_simulations * 100.0)
            .collect();

        all_times_counts.push((times, counts, display_name));
    }

    let mut fg = Figure::new();
    let mut axes = fg
        .axes2d()
        .set_margins(&vec![
            MarginSide::MarginLeft(0.08),
            MarginSide::MarginRight(0.95),
            MarginSide::MarginBottom(0.15),
            MarginSide::MarginTop(0.85),
        ])
        .set_x_range(AutoOption::Fix(0.0), AutoOption::Auto)
        .set_y_range(AutoOption::Fix(0.0), AutoOption::Auto)
        .set_x_label(
            "Tijd (minuten)",
            &vec![
                LabelOption::Font("Arial", 50.0),
                LabelOption::TextOffset(0.0, -3.0),
            ],
        )
        .set_y_label(
            "Simulaties (%)",
            &vec![
                LabelOption::Font("Arial", 50.0),
                LabelOption::TextOffset(-5.0, 0.0),
            ],
        )
        .set_x_ticks(
            Some((AutoOption::Auto, 0)),
            &[],
            &vec![LabelOption::Font("Arial", 20.0)],
        )
        .set_y_ticks(
            Some((AutoOption::Auto, 0)),
            &[],
            &vec![
                LabelOption::Font("Arial", 20.0),
                LabelOption::Rotate(90.0),
                LabelOption::TextOffset(0.0, 1.0),
            ],
        )
        .set_legend(
            Coordinate::Graph(0.98),
            Coordinate::Graph(0.98),
            &vec![],
            &vec![LabelOption::Font("Arial", 40.0)],
        );

    for (idx, (times, counts, name)) in all_times_counts.iter().enumerate() {
        let mut times_f64: Vec<f64> = times.iter().map(|&x| x as f64).collect();
        let mut counts_f64: Vec<f64> = counts.clone();

        times_f64.insert(0, 0.0);
        counts_f64.insert(0, 0.0);

        if let Some(&last_time) = times.last() {
            times_f64.push((last_time + 1) as f64);
            counts_f64.push(0.0);
        }

        let mut ma_counts = moving_average(&counts_f64, 8);

        if let Some(&last_time) = times.last() {
            let end_time = (last_time + 1) as f64;
            times_f64.push(end_time);
            counts_f64.push(0.0);
            ma_counts.push(0.0);
        }

        let color = colors[idx % colors.len()];

//         // plot original line (thin)
//         axes = axes.lines(
//             &times_f64,
//             &counts_f64,
//             &vec![
//                 Caption(format!("{} (raw)", name).as_str()),
//                 LineWidth(2.0),
//                 Color(color),
//             ],
//         );

        // plot moving average line (thick)
        axes = axes.lines(
            &times_f64,
            &ma_counts,
            &vec![
                Caption(format!("{}", name).as_str()),
                LineWidth(8.0),
                Color(color),
            ],
        );
    }


    let _ = fg.show();

    println!("Plot completed with {} datasets", all_times_counts.len());

    Ok(())
}
