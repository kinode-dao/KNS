use std::env;
use std::io::Write;
use trust_dns_proto::serialize::binary::BinEncodable;
use trust_dns_proto::serialize::binary::BinEncoder;
use trust_dns_proto::rr::domain::Name;
use trust_dns_proto::op::message::Message;
use hex;

fn main() {
    let args: Vec<String> = env::args().collect();

    if args[1] == "--to-hex" {

        let domain_name = &args[2];
        let name = Name::from_ascii(domain_name).unwrap();

        let wire_format_bytes = match name.to_bytes() {
            Ok(bytes) => bytes,
            Err(_) => panic!("failed to convert name to bytes"),
        };

        let wire_format_hex = hex::encode(&wire_format_bytes);

        let wire_format_hex_bytes = wire_format_hex.as_bytes();

        std::io::stdout().write_all(
            wire_format_hex_bytes
            // &wire_format_hex_bytes[..wire_format_hex_bytes.len()-1]
        );
        println!();
        std::io::stdout().flush().unwrap();

        // println!("{:?}", wire_format_hex);

    } else if args[1] == "--from-hex" {

        let wire_format_hex = &args[2];

        let wire_format_bytes = match hex::decode(&wire_format_hex) {
            Ok(result) => result,
            Err(_) => panic!("failed to convert to bytes"),
        };

        let mut i = 0;
        let mut result = Vec::new();

        while i < wire_format_bytes.len() {
            let len = wire_format_bytes[i] as usize;
            if len == 0 { break; }
            let end = i + len + 1;
            let mut span = wire_format_bytes[i+1..end].to_vec();
            span.push('.' as u8);
            result.push(span);
            i = end;
        };

        let flat: Vec<_> = result.into_iter().flatten().collect();

        let fqdn = match String::from_utf8(flat) {
            Ok(string) => string,
            Err(_) => panic!("failed"),
        };

        println!("{:?}", fqdn);

    }



    // // let message = match Message::from_vec(&wire_format_bytes) {
    // //     Ok(message) => message,
    // //     Err(_) => panic!("failed to parse message"),
    // // };

    // println!("Decoded: {:?}", wire_format_bytes);

}
