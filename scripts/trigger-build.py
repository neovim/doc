#!/usr/bin/env python

from __future__ import print_function
from argparse import ArgumentParser
import json
import os
import sys
try:
    import requests
except ImportError:
    print('Please install Requests (http://python-requests.org).')
    raise


def travis_request(endpoint, method='get', post_data=None, travis_token=None):
    url = 'https://api.travis-ci.org/{0}'.format(endpoint)
    headers = {'Accept': 'application/vnd.travis-ci.2+json'}

    if travis_token:
        headers['Authorization'] = 'token "{0}"'.format(travis_token)

    if post_data:
        method = 'post'

    response = requests.request(method, url, params=post_data, headers=headers)

    try:
        # Try json() method of recent Requests versions.
        return response.json()
    except AttributeError:
        # Won't work with Python 3.
        # Assumption: Distributions that use Python 3 as default
        # also provide recent Requests.
        return json.loads(response.content)


def get_latest_build_id(repo_slug, branch):
    response = travis_request('repos/{0}/branches/{1}'.format(repo_slug,
                                                              branch))
    return response['branch']['id']


def get_latest_job_id(build_id, job_substring):
    response = travis_request('builds/{0}'.format(build_id))
    jobs = [job for job in response['jobs']
            if job_substring in job['config']['env']]
    if len(jobs) == 0:
        raise RuntimeError("No job contains '{0}'.".format(job_substring))
    if len(jobs) > 1:
        raise RuntimeError("Several jobs contain '{0}'.".format(job_substring))
    return jobs[0]['id']


def restart(entity_type, build_id, travis_token):
    assert(entity_type == 'job' or entity_type == 'build')
    response = travis_request('{0}s/{1}/restart'.format(entity_type, build_id),
                              travis_token=travis_token,
                              method='post')
    return os.linesep.join(response['flash'][0].values())


def get_or_request_travis_token():
    if 'TRAVIS_TOKEN' in os.environ:
        travis_token = os.environ['TRAVIS_TOKEN']
    else:
        if 'GH_TOKEN' not in os.environ:
            raise RuntimeError(('Neither GH_TOKEN nor TRAVIS_TOKEN '
                                'environment variables set.'))

        gh_token = os.environ['GH_TOKEN']
        response = travis_request('auth/github',
                                  post_data={'github_token': gh_token})
        if 'access_token' not in response:
            raise RuntimeError('Could not obtain a Travis token. '
                               'Is GH_TOKEN valid?')
        travis_token = response['access_token']

    return travis_token


if __name__ == '__main__':
    try:
        parser = ArgumentParser(description='Restart the latest Travis build '
                                            'for a repository and branch. '
                                            'One of the following environment '
                                            'variables is required: '
                                            'GH_TOKEN or TRAVIS_TOKEN.')
        parser.add_argument('--repo-slug',
                            default='neovim/bot-ci',
                            help='default: %(default)s')
        parser.add_argument('--branch',
                            default='master',
                            help='default: %(default)s')
        parser.add_argument('--job',
                            help='Restart an individual job. If omitted, '
                                 'the latest build (=all jobs) is restarted.')
        args = parser.parse_args()

        travis_token = get_or_request_travis_token()
        print('Restarting build on {0}:{1}:'.format(args.repo_slug,
                                                    args.branch),
              end=' ')
        build_id = get_latest_build_id(args.repo_slug, args.branch)
        if (args.job):
            job_id = get_latest_job_id(build_id, args.job)
            print('https://travis-ci.org/{0}/jobs/{1}'.format(args.repo_slug,
                                                              job_id))
            message = restart('job', job_id, travis_token)
        else:
            print('https://travis-ci.org/{0}/builds/{1}'.format(args.repo_slug,
                                                                build_id))
            message = restart('build', build_id, travis_token)
        print(message)
    except Exception as e:
        print('Error: {0}'.format(e))
        sys.exit(1)
