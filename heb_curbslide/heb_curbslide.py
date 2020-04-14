import json
import os
from datetime import datetime
import time

import boto3
import requests


def check_timestamp_indb(sdb):
    try:
        response = sdb.select(
            SelectExpression="select timestamp from `{0}`".format(
                os.environ["simpledb_domain"]
            )
        )
        lastcheckin = response["Items"][0]["Attributes"][0]["Value"]
        return int(lastcheckin)
    except:
        return 0


def update_timestamp_currenttime(sdb):
    sdb.put_attributes(
        DomainName=os.environ["simpledb_domain"],
        ItemName="last_checkin",
        Attributes=[
            {
                "Name": "timestamp",
                "Value": str(int(time.time())),
                "Replace": True,
            },
        ],
    )


def slide_on_in():

    headers = {
        "Connection": "keep-alive",
        "Accept": "application/json, text/plain, */*",
        "Sec-Fetch-Dest": "empty",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4109.1 Safari/537.36",
        "DNT": "1",
        "Sec-Fetch-Site": "same-origin",
        "Sec-Fetch-Mode": "cors",
        "Referer": "https://www.heb.com/?context=curbside",
        "Accept-Language": "en-US,en;q=0.9",
    }

    params = (
        ("store_id", os.environ["store_number"]),
        ("days", "15"),
        ("fulfillment_type", "pickup"),
    )

    response = requests.get(
        "https://www.heb.com/commerce-api/v1/timeslot/timeslots",
        headers=headers,
        params=params,
    )
    r = response.json()
    if len(r['items']) == 0:
        print("[!] - No timeslots @ {}".format(datetime.now()))
        return None
    elif len(r['items']) > 0:
        print("[!] - Slots available @ {}".format(datetime.now()))
        counter = 0
        results = {}
        results["store"] = r["pickupStore"]["name"]
        results["address"] = r["pickupStore"]["address1"]
        results["slots"] = []
        for item in r["items"]:
            while len(results["slots"]) < 3:
                results["slots"].append(item["timeslot"]["startTime"])
                counter = +1
        return results
    elif r:
        print("[!] - Something went seriously wrong")


def main(event, context):
    sdbclient = boto3.client("sdb")
    snsclient = boto3.client("sns")
    if (int(time.time()) - check_timestamp_indb(sdbclient)) < 259200:
        print('[!] - Exiting cleanly, success within last 3 days')
        results = None
    else:
        print('[!] - No successful checks in last 3 days, checking now')
        results = slide_on_in()
        if results:
            message = "[!] - {} at {} has slots available at {}".format(
                results["store"], results["address"], results["slots"]
            )
            print(message)
            snsclient.publish(
                TopicArn=os.environ["sns_topic"], Message=message,
            )
            update_timestamp_currenttime(sdbclient)
        else:
            print("[!] - No slots available at {}.".format(datetime.now()))
            print("[!] - Exited cleanly. Goodbye.")

