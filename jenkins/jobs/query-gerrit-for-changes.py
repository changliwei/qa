import sys
import os
import argparse
import paramiko
import json
import logging


logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)


def create_query_expression(owners):
    return '( ' + ' OR '.join('owner:%s' % owner for owner in owners) + ') '


def query_for_extra_changes(changes):
    if changes:
        result = ' OR '
        result += ' OR '.join('( change:%s AND status:open )' % change for change in changes)
        return result
    else:
        return ''


def main(args):
    hostname = args.host
    port = int(args.port)
    username = args.username
    keyfile = args.keyfile
    owners = args.watched_owners.split(',')

    client = paramiko.SSHClient()
    client.load_system_host_keys()
    client.set_missing_host_key_policy(paramiko.WarningPolicy())
    client.connect(hostname, port=port, username=username, key_filename=keyfile)
    stdin, stdout, stderr = client.exec_command(
        "gerrit query --patch-sets --format=JSON status:open AND %s %s" %
            (create_query_expression(owners), query_for_extra_changes(args.change)))


    def to_change_record(change):
        logger.debug("Processing change: %s" % change)
        if 'patchSets' not in change:
            return
        patchsets = [(int(ps['number']), ps['ref']) for ps in change['patchSets']]
        latest_patchset = sorted(patchsets, key=lambda x: x[0], reverse=True)[0]

        project = change['project']

        changeref = latest_patchset[1]
        change_url = change['url']
        return (change['createdOn'], project, changeref, change_url)


    change_records = []
    for line in stdout.readlines():
        change = json.loads(line)
        change_record = to_change_record(change)
        if change_record:
            change_records.append(change_record)


    for change_record in sorted(change_records):
        sys.stdout.write("%s %s %s\n" % change_record[1:])

    client.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Get changes repo from OpenStack gerrit')
    parser.add_argument('username', help='Gerrit username to use')
    parser.add_argument('keyfile', help='SSH key to use')
    parser.add_argument('watched_owners',
        help='Comma separated list of Owner ids whose changes to be collected')
    parser.add_argument('--host', default='review.openstack.org',
        help='Specify a host. default: review.openstack.org')
    parser.add_argument('--port', default='29418',
        help='Specify a port. default: 29418')
    parser.add_argument('--change', action='append',
        help='Extra change ids to pick')
    args = parser.parse_args()
    main(args)
