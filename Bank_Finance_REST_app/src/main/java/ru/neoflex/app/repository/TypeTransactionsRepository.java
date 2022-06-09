package ru.neoflex.app.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ru.neoflex.app.domain.TypeTransactions;

public interface TypeTransactionsRepository extends JpaRepository<TypeTransactions, Long> {
}
