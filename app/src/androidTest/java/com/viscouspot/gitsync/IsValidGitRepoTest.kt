package com.viscouspot.gitsync

import com.viscouspot.gitsync.util.Helper.isValidGitRepo
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class IsValidGitRepoTest {

    @Test
    fun testValidHttpGitRepo() {
        val validUrls = listOf(
            "https://github.com/user/repo.git",
            "http://github.com/user/repo.git",
            "https://github.com/user/repo",
        )

        validUrls.forEach { url ->
            assertNull("Expected true for $url", isValidGitRepo(url))
        }
    }

    @Test
    fun testValidSshGitRepo() {
        val validUrls = listOf(
            "git@github.com:user/repo.git",
            "ssh://git@github.com:user/repo.git",
            "git@bitbucket.org:user/repo.git",
            "git@github.com:user/repo",
        )

        validUrls.forEach { url ->
            assertNull("Expected true for $url", isValidGitRepo(url, true))
        }
    }


    @Test
    fun testInvalidGitRepo() {
        val invalidUrls = listOf(
            "ftp://github.com/user/repo.git",      // Invalid protocol
            "github.com/user/repo.git",            // Missing protocol
            "git://github.com/user/repo.git",      // Invalid protocol (git://)
        )

        invalidUrls.forEach { url ->
            assertNotNull("Expected false for $url", isValidGitRepo(url))
            assertNotNull("Expected false for $url", isValidGitRepo(url, true))
        }
    }
}