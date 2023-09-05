use std::error::Error;
use std::fmt;

#[derive(Debug)]
struct MyError {
    details: String,
}

impl MyError {
    fn new(msg: &str) -> MyError {
        MyError {
            details: msg.to_string(),
        }
    }
}

impl fmt::Display for MyError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", self.details)
    }
}

impl Error for MyError {
    fn description(&self) -> &str {
        &self.details
    }
}

type BoxError = Box<dyn Error>;

pub fn handle(body: Vec<u8>) -> Result<Vec<u8>, BoxError> {
    match String::from_utf8(body) {
        Ok(body) => match body.parse::<i32>() {
            Ok(n) => Ok(format!("{}", n + 1).as_bytes().to_vec()),
            Err(_) => {
                let error = MyError::new("cannot parse the body as an integer number");
                Err(Box::new(error))
            }
        },
        Err(_) => {
            let error = MyError::new("cannot parse the input as an UTF-8 string");
            Err(Box::new(error))
        }
    }
}
