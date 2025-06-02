use clap::Parser;
use prettytable::{Table, Row, Cell};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    #[arg(short, long)]
    input: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(untagged)]
enum TweakValue {
    Single(f64),
    Range([f64; 2]),
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(tag = "message", rename_all = "snake_case")]
enum Event {
    TweakedConstants {
        tweaks: HashMap<String, TweakValue>,
    },
    StopConditionReached {
        iteration: u32,
        tick: u32,
        bots: Vec<Bot>,
    },
    ExperimentFinished {
        duration: f64,
    },
    AllDepleted {},
    BotKilled {
        id: u32,
        iteration: u32,
        tick: u32,
    },
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Data {
    id: u32,
    r#type: String,
    content: u32,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Bot {
    id: u32,
//     data: Vec<Data>,
    energy: f64,
}

const MAX_ENERGY_PER_BOT: f64 = 1080.0;

fn main() {
    let args = Args::parse();

    let json_data = fs::read_to_string(&args.input).expect("Unable to read file");
    let events: Vec<Event> = serde_json::from_str(&json_data).expect("Invalid JSON format");

    let mut last_tweaks = HashMap::new();
    let mut paired_events = vec![];
    let mut depleted_iterations = vec![];

    for event in events {
        match event {
            Event::TweakedConstants { tweaks } => {
                last_tweaks = tweaks;
            }
            Event::StopConditionReached {
                iteration,
                tick,
                bots,
            } => {
                paired_events.push((tick, iteration, last_tweaks.clone(), bots));
            }
            Event::ExperimentFinished { duration } => {
                println!("Experiment finished after {} seconds.", duration);
            }
            Event::AllDepleted {} => {
                let iteration = paired_events.last().map(|(_, iteration, _, _)| *iteration).unwrap_or(0);
                depleted_iterations.push(iteration);
            }
            Event::BotKilled { .. } => {
            }
        }
    }

    let energy_values: Vec<f64> = paired_events
        .iter()
        .map(|(_, _, _, bots)| {
            bots.iter().map(|bot| bot.energy).sum::<f64>()
        })
        .collect();

    let average_energy = energy_values.iter().sum::<f64>() / energy_values.len() as f64;
    let variance = energy_values
        .iter()
        .map(|&energy| (energy - average_energy).powi(2))
        .sum::<f64>()
        / energy_values.len() as f64;

    let std_dev = variance.sqrt();

    let standard_error = std_dev / (energy_values.len() as f64).sqrt();
    let ci_95_lower = average_energy - 1.96 * standard_error;
    let ci_95_upper = average_energy + 1.96 * standard_error;

    let max_possible_per_bot = MAX_ENERGY_PER_BOT;
    let average_bots_per_iteration = paired_events
        .iter()
        .map(|(_, _, _, bots)| bots.len())
        .sum::<usize>() as f64 / paired_events.len() as f64;

    let max_possible_energy = max_possible_per_bot * average_bots_per_iteration;

    let average_energy_percent = (average_energy / max_possible_energy) * 100.0;
    let std_dev_percent = (std_dev / max_possible_energy) * 100.0;
    let ci_95_lower_percent = (ci_95_lower / max_possible_energy) * 100.0;
    let ci_95_upper_percent = (ci_95_upper / max_possible_energy) * 100.0;

    let mut table = Table::new();
    table.add_row(Row::new(vec![
        Cell::new("Statistic"),
        Cell::new("Raw Value"),
        Cell::new("Percentage")
    ]));

    table.add_row(Row::new(vec![
        Cell::new("Average energy"),
        Cell::new(&format!("{:.4}", average_energy)),
        Cell::new(&format!("{:.2}%", average_energy_percent))
    ]));

    table.add_row(Row::new(vec![
        Cell::new("Standard deviation"),
        Cell::new(&format!("{:.4}", std_dev)),
        Cell::new(&format!("{:.2}%", std_dev_percent))
    ]));

    table.add_row(Row::new(vec![
        Cell::new("95% CI - lower"),
        Cell::new(&format!("{:.4}", ci_95_lower)),
        Cell::new(&format!("{:.2}%", ci_95_lower_percent))
    ]));

    table.add_row(Row::new(vec![
        Cell::new("95% CI - upper"),
        Cell::new(&format!("{:.4}", ci_95_upper)),
        Cell::new(&format!("{:.2}%", ci_95_upper_percent))
    ]));

    table.printstd();

    paired_events.sort_by_key(|&(tick, _, _, _)| tick);
    let best = paired_events.iter().take(5).cloned().collect::<Vec<_>>();

    paired_events.sort_by_key(|&(tick, _, _, _)| std::cmp::Reverse(tick));
    let worst = paired_events.iter().take(4).cloned().collect::<Vec<_>>();

    display_combined_tweaks_table(&best, &worst);
    analyze_good_bad_parameters(&best, &worst);

    println!();

    let not_found_iterations = paired_events
        .iter()
        .filter(|(tick, _, _, _)| *tick == 1000000)
        .count();

    println!("Iterations where target not found: {}", not_found_iterations);
    println!("Iterations where depleted: {}", depleted_iterations.len());
    println!("Iterations where target found: {}", paired_events.len() - not_found_iterations - depleted_iterations.len());

    let average_duration = paired_events
            .iter()
            .map(|(tick, _, _, _)| {
                tick
            })
            .sum::<u32>()
            / paired_events.len() as u32;

    println!("Average duration: {} ticks ({}:{})", average_duration, average_duration / 3600, average_duration % 3600 / 60);

    let found_iterations = paired_events
        .iter()
        .filter_map(|(tick, iteration, _, _)| {
            if *tick == 1000000 || depleted_iterations.contains(iteration) {
                None
            } else {
                Some(*tick)
            }
        });

    let average_duration_found = found_iterations
        .clone()
        .sum::<u32>()
        / found_iterations.count() as u32;

    println!("Average duration (found): {} ticks ({}:{})", average_duration_found, average_duration_found / 3600, average_duration_found % 3600 / 60);
}

fn display_combined_tweaks_table(
    best: &[(u32, u32, HashMap<String, TweakValue>, Vec<Bot>)],
    worst: &[(u32, u32, HashMap<String, TweakValue>, Vec<Bot>)],
) {

    let mut table = Table::new();

    let mut all_keys = std::collections::BTreeSet::new();
    for (_, _, tweaks, _) in best.iter().chain(worst.iter()) {
        for key in tweaks.keys() {
            all_keys.insert(key.clone());
        }
    }

    let mut header = vec![Cell::new("Parameter")];
    for (i, _) in best.iter().enumerate() {
        header.push(Cell::new(&format!("#{}", i + 1)));
    }
    header.push(Cell::new("|"));
    for (i, _) in worst.iter().enumerate() {
        header.push(Cell::new(&format!("#last-{}", i)));
    }
    table.add_row(Row::new(header));

    for key in all_keys {
        let mut row = vec![Cell::new(&key)];
        for (_, _, tweaks, _) in best {
            if let Some(value) = tweaks.get(&key) {
                row.push(Cell::new(&match value {
                    TweakValue::Single(v) => format!("{:.4}", v),
                    TweakValue::Range([v1, v2]) => format!("[{:.4}, {:.4}]", v1, v2),
                }));
            } else {
                row.push(Cell::new("-"));
            }
        }
        row.push(Cell::new("|"));
        for (_, _, tweaks, _) in worst {
            if let Some(value) = tweaks.get(&key) {
                row.push(Cell::new(&match value {
                    TweakValue::Single(v) => format!("{:.4}", v),
                    TweakValue::Range([v1, v2]) => format!("[{:.4}, {:.4}]", v1, v2),
                }));
            } else {
                row.push(Cell::new("-"));
            }
        }
        table.add_row(Row::new(row));
    }

    let mut ticks_row = vec![Cell::new("Duration (ticks)")];
    for (tick, _, _, _) in best {
        ticks_row.push(Cell::new(&tick.to_string()));
    }
    ticks_row.push(Cell::new("|"));
    for (tick, _, _, _) in worst {
        ticks_row.push(Cell::new(&tick.to_string()));
    }
    table.add_row(Row::new(ticks_row));

    let mut minutes_row = vec![Cell::new("Duration (minutes)")];
    for (tick, _, _, _) in best {
        let minutes = *tick / 3600;
        let seconds = *tick % 3600 / 60;
        minutes_row.push(Cell::new(&format!("{}:{}", minutes, seconds)));
    }
    minutes_row.push(Cell::new("|"));
    for (tick, _, _, _) in worst {
        let minutes = *tick / 3600;
        let seconds = *tick % 3600 / 60;
        minutes_row.push(Cell::new(&format!("{}:{}", minutes, seconds)));
    }
    table.add_row(Row::new(minutes_row));

    table.printstd();
}

fn analyze_good_bad_parameters(
    best: &[(u32, u32, HashMap<String, TweakValue>, Vec<Bot>)],
    worst: &[(u32, u32, HashMap<String, TweakValue>, Vec<Bot>)],
) {
    let mut good_values: HashMap<String, Vec<f64>> = HashMap::new();
    let mut bad_values: HashMap<String, Vec<f64>> = HashMap::new();

    for (_, _, tweaks, _) in best {
        for (key, value) in tweaks {
            let v = match value {
                TweakValue::Single(v) => *v,
                TweakValue::Range([v1, _]) => *v1, // OR take average of v1 and v2
            };
            good_values.entry(key.clone()).or_default().push(v);
        }
    }

    for (_, _, tweaks, _) in worst {
        for (key, value) in tweaks {
            let v = match value {
                TweakValue::Single(v) => *v,
                TweakValue::Range([v1, _]) => *v1,
            };
            bad_values.entry(key.clone()).or_default().push(v);
        }
    }

    println!("=== Parameter Analysis ===");
    for key in good_values.keys().chain(bad_values.keys()).collect::<std::collections::BTreeSet<_>>() {
        let good_vec = Vec::new();
        let bad_vec = Vec::new();
        let good = good_values.get(key).unwrap_or(&good_vec);
        let bad = bad_values.get(key).unwrap_or(&bad_vec);

        if good.is_empty() && bad.is_empty() {
            continue;
        }

        let good_avg = if !good.is_empty() { good.iter().sum::<f64>() / good.len() as f64 } else { 0.0 };
        let bad_avg = if !bad.is_empty() { bad.iter().sum::<f64>() / bad.len() as f64 } else { 0.0 };

        println!("Parameter: {}", key);
        println!("  Good average: {:.4}", good_avg);
        println!("  Bad average:  {:.4}", bad_avg);

        if !good.is_empty() {
            let min = good.iter().cloned().fold(f64::INFINITY, f64::min);
            let max = good.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
            println!("  Good range: [{:.4}~{:.4}]", min, max);
        }

        if !bad.is_empty() {
            let min = bad.iter().cloned().fold(f64::INFINITY, f64::min);
            let max = bad.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
            println!("  Bad range:  [{:.4}~{:.4}]", min, max);
        }
        println!();
    }
}


