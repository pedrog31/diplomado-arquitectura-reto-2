use aws_lambda_events::event::sqs::SqsEvent;
use aws_sdk_sesv2::types::{Body, Content, Destination, EmailContent, Message};
use lambda_runtime::{run, service_fn, Error, LambdaEvent};
use chrono::Utc;
use serde::Deserialize;
use tracing::info;

#[derive(Deserialize)]
struct Coordinates {
    latitude: String,
    longitude: String,
}

#[derive(Deserialize)]
struct EventPayload {
    r#type: String,
    vehicle_plate: String,
    coordinates: Coordinates,
}

async fn handler(event: LambdaEvent<SqsEvent>) -> Result<(), Error> {
    let config = aws_config::load_defaults(aws_config::BehaviorVersion::latest()).await;
    let ses = aws_sdk_sesv2::Client::new(&config);
    let from = std::env::var("SES_FROM_EMAIL")?;
    let to = std::env::var("SES_TO_EMAIL")?;

    for record in event.payload.records {
        let body = record.body.unwrap_or_default();
        info!(message = %body, "Processing SQS message");

        if let Ok(payload) = serde_json::from_str::<EventPayload>(&body) {
            if payload.r#type == "Emergency" {
                info!(vehicle = %payload.vehicle_plate, "Emergency detected, sending email");
                ses.send_email()
                    .from_email_address(&from)
                    .destination(Destination::builder().to_addresses(&to).build())
                    .content(
                        EmailContent::builder()
                            .simple(
                                Message::builder()
                                    .subject(Content::builder().data("Emergency Alert").build()?)
                                    .body(
                                        Body::builder()
                                            .text(
                                                Content::builder()
                                                    .data(format!(
                                                        "Emergency from vehicle: {}\nCoordinates: {}, {}",
                                                        payload.vehicle_plate,
                                                        payload.coordinates.latitude,
                                                        payload.coordinates.longitude
                                                    ))
                                                    .build()?,
                                            )
                                            .build(),
                                    )
                                    .build(),
                            )
                            .build(),
                    )
                    .send()
                    .await?;
                info!(vehicle = %payload.vehicle_plate, sent_at = %Utc::now().format("%Y-%m-%d %H:%M:%S UTC"), "Email sent successfully");
            }
        }
    }
    Ok(())
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    tracing_subscriber::fmt()
        .json()
        .with_target(false)
        .without_time()
        .init();
    run(service_fn(handler)).await
}
