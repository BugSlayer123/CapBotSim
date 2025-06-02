use std::sync::Arc;
use std::thread;

use clap::Parser;
use gnuplot::{AxesCommon, Caption, Figure, PlotOption::LineWidth};
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

#[derive(Parser, Debug)]
#[command(version, about)]
struct Args {
    #[arg(long, required = true)]
    log_file: String,
    #[arg(long, value_delimiter = ' ', num_args = 1.., default_values_t = Stat::all())]
    stats: Vec<Stat>,
    #[arg(long, value_delimiter = ' ', num_args = 1..)]
    bots: Vec<u16>,
    #[arg(long)]
    seconds: bool,
}

#[derive(clap::ValueEnum, Clone, Debug, Serialize)]
#[serde(rename_all = "kebab-case")]
enum Stat {
    DataPerBot,
    EnergyPerBot,
    StatusPerBot,
    DataCumulative,
    EnergyCumulative,
    Locations,
}

impl std::fmt::Display for Stat {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::DataPerBot => write!(f, "data-per-bot"),
            Self::EnergyPerBot => write!(f, "energy-per-bot"),
            Self::StatusPerBot => write!(f, "status-per-bot"),
            Self::DataCumulative => write!(f, "data-cumulative"),
            Self::EnergyCumulative => write!(f, "energy-cumulative"),
            Self::Locations => write!(f, "locations"),
        }
    }
}

#[derive(Debug, Deserialize)]
struct Record {
    tick: u64,
    bot_id: u16,
    energy: f64,
    #[serde(deserialize_with = "parse_data_field")]
    data: Vec<u8>,
    x: f64,
    y: f64,
    //    vel_x: f32,
    //    vel_y: f32,
    status: String,
    r#type: String,
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

impl Stat {
    fn all() -> Vec<Stat> {
        vec![
            Stat::DataPerBot,
            Stat::EnergyPerBot,
            Stat::StatusPerBot,
            Stat::DataCumulative,
            Stat::EnergyCumulative,
            Stat::Locations,
        ]
    }

    pub fn title(&self) -> &'static str {
        match self {
            Self::DataPerBot => "Bot Data Over Time",
            Self::EnergyPerBot => "Bot Energy Over Time",
            Self::StatusPerBot => "Bot Status Over Time",
            Self::DataCumulative => "Total Data In System (Bots) Over Time",
            Self::EnergyCumulative => "Total Energy In System (Bots) Over Time",
            Self::Locations => "Locations of Bots Over Time",
        }
    }

    pub fn labels(&self) -> (&'static str, &'static str) {
        match self {
            Self::DataPerBot => ("Time (ticks)", "Presence of Data (0 or 1)"),
            Self::EnergyPerBot => ("Time (ticks)", "Energy Per Bot (J)"),
            Self::StatusPerBot => ("Time (ticks)", "Status"),
            Self::DataCumulative => ("Time (ticks)", "Total Data In System (Bots)"),
            Self::EnergyCumulative => ("Time (ticks)", "Total Energy In System (J)"),
            Self::Locations => ("X Coordinate", "Y Coordinate"),
        }
    }

    pub fn data(
        &self,
        records: &Vec<Record>,
        bot_ids: &Vec<u16>,
    ) -> Vec<(String, Vec<f64>, Vec<f64>)> {
        let bot_records: Vec<&Record> = records.iter().filter(|r| r.r#type == "bot").collect();
        let mut grouped_by_tick: BTreeMap<u64, Vec<&Record>> = BTreeMap::new();
        let mut grouped_by_bot: BTreeMap<u16, Vec<&Record>> = BTreeMap::new();

        for record in &bot_records {
            grouped_by_tick.entry(record.tick).or_default().push(record);

            if !bot_ids.is_empty() && !bot_ids.contains(&record.bot_id) {
                continue;
            }

            grouped_by_bot
                .entry(record.bot_id)
                .or_default()
                .push(record);
        }

        let ticks: Vec<f64> = grouped_by_tick.keys().map(|&i| i as f64).collect();

        match self {
            Self::DataPerBot => {
                let data: Vec<u8> = bot_records
                    .iter()
                    .map(|r| r.data.clone())
                    .max_by_key(|v| v.len())
                    .expect("Couldn't get data vector");

                grouped_by_bot
                    .iter()
                    .flat_map(|(bot_id, records)| {
                        data.iter().map(|value| {
                            (
                                format!("Bot {} - Data {}", bot_id.clone(), value),
                                ticks.clone(),
                                records
                                    .iter()
                                    .map(|r| if r.data.contains(&value) { 1.0 } else { 0.0 })
                                    .collect(),
                            )
                        })
                    })
                    .collect()
            }
            Self::EnergyPerBot => grouped_by_bot
                .iter()
                .map(|(bot_id, records)| {
                    (
                        format!("Bot {}", bot_id),
                        ticks.clone(),
                        records.iter().map(|r| r.energy as f64).collect(),
                    )
                })
                .collect(),
            Self::StatusPerBot => grouped_by_bot
                .iter()
                .map(|(bot_id, records)| {
                    (
                        format!("Bot {}", bot_id),
                        ticks.clone(),
                        records
                            .iter()
                            .map(|r| match r.status.as_str() {
                                "abort" => 0.0,
                                "active_aborting" => 0.0,
                                "active" => 1.0,
                                "trophallaxis" => 2.0,
                                "data_transfer" => 3.0,
                                _ => unimplemented!("status {} is not implemented", r.status),
                            })
                            .collect(),
                    )
                })
                .collect(),
            Self::DataCumulative => {
                let data: Vec<u8> = bot_records
                    .iter()
                    .map(|r| r.data.clone())
                    .max_by_key(|v| v.len())
                    .expect("Couldn't get data vector");

                data.iter()
                    .map(|value| {
                        (
                            value.to_string(),
                            ticks.clone(),
                            grouped_by_tick
                                .values()
                                .map(|records| {
                                    records
                                        .iter()
                                        .filter(|record| record.data.contains(&value))
                                        .count() as f64
                                })
                                .collect::<Vec<_>>(),
                        )
                    })
                    .collect()
            }

            Self::EnergyCumulative => vec![(
                "Total Energy".to_string(),
                ticks,
                grouped_by_tick
                    .values()
                    .map(|records| records.iter().map(|record| record.energy as f64).sum())
                    .collect(),
            )],
            Self::Locations => {
                let max_y = grouped_by_bot
                    .values()
                    .flat_map(|records| records.iter().map(|r| r.y))
                    .fold(f64::NEG_INFINITY, f64::max);

                grouped_by_bot
                    .iter()
                    .map(|(bot_id, records)| {
                        (
                            format!("Bot {}", bot_id),
                            records.iter().map(|r| r.x).collect(),
                            records.iter().map(|r| max_y - r.y).collect(),
                        )
                    })
                    .collect()
            }
        }
    }
}

fn parse_csv(path: String) -> Result<Vec<Record>, Box<dyn std::error::Error>> {
    let file = std::fs::File::open(path)?;
    let mut rdr = csv::Reader::from_reader(file);
    let mut records = Vec::new();

    for result in rdr.deserialize() {
        let record: Record = result?;
        records.push(record);
    }

    Ok(records)
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    let bot_ids = Arc::new(args.bots);

    let records = parse_csv(args.log_file).expect("Error while reading in records");
    let records = Arc::new(records);

    let handles: Vec<_> = args
        .stats
        .into_iter()
        .map(|stat| {
            let records = Arc::clone(&records);
            let bot_ids = Arc::clone(&bot_ids);

            thread::spawn(move || {
                let mut fg = Figure::new();
                let (x_label, y_label) = stat.labels();

                let mut axes = fg
                    .axes2d()
                    .set_title(stat.title(), &Vec::new())
                    .set_x_label(x_label, &Vec::new())
                    .set_y_label(y_label, &Vec::new());

                for (name, x, y) in stat.data(&records, &bot_ids) {
                    axes = axes.lines(&x, &y, &[Caption(name.as_str()), LineWidth(2.0)]);
                }

                let _ = fg.show();
            })
        })
        .collect();

    for handle in handles {
        handle.join().unwrap();
    }

    Ok(())
}
