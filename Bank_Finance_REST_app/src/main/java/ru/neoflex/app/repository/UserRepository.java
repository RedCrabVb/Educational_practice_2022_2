package ru.neoflex.app.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ru.neoflex.app.domain.User;

public interface UserRepository extends JpaRepository<User, Long> {
    User findByLogin(String login);
}