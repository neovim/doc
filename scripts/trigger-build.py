from __future__ import print_function
import json
import os
import sys
from urllib import urlencode
import urllib2
import datetime

def travis_request(endpoint, post_data=None, travis_token=None):
    url = 'https://api.travis-ci.org/{0}'.format(endpoint)
    data = urlencode(post_data) if not post_data is None else None
    headers = {'Accept': 'application/vnd.travis-ci.2+json',
               'User-Agent': 'Travis-justinmk-aws/1.0.0'}

    if travis_token:
        headers['Authorization'] = 'token "{0}"'.format(travis_token)

    print('url: '+url)
    print('post_data: '+str(post_data))
    print('headers: '+str(headers))

    response = urllib2.urlopen(urllib2.Request(url=url,
                               data=data,
                               headers=headers))
    return json.loads(response.read())


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
                              post_data="", #force urllib2 to POST.
                              travis_token=travis_token)
    return os.linesep.join(response['flash'][0].values())

def get_or_request_travis_token(gh_token):
    response = travis_request('auth/github',
                              post_data={'github_token': gh_token})
    print(str(response))
    if 'access_token' not in response:
        raise RuntimeError('Could not obtain a Travis token. '
                           'Is GH_TOKEN valid?')
    travis_token = response['access_token']

    return travis_token

def lambda_handler(event, context):
    repo_slug = 'neovim/bot-ci'
    branch = 'master'
    job = "ALL" if 20 == datetime.datetime.utcnow().hour else "assign-labels"
    travis_token = get_or_request_travis_token('XXX')

    print('Restarting "{0}" build on {1}:{2}:'.format(job, repo_slug, branch))
    build_id = get_latest_build_id(repo_slug, branch)
    if (job != "ALL"):
        job_id = get_latest_job_id(build_id, job)
        message = restart('job', job_id, travis_token)
    else:
        message = restart('build', build_id, travis_token)
    print(message)
    return message

if __name__ == '__main__':
    lambda_handler({}, None)
